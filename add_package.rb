#!/usr/bin/env ruby
require "aws-sdk"
require "mixlib/cli"
require "mixlib/shellout"
require_relative "platforms"

class SensuPackageCLI
  include Mixlib::CLI

  option :channel,
  :short => "-c CHANNEL",
  :long => "--channel CHANNEL",
  :default => "unstable",
  :description => "The channel to use [stable|unstable]",
  :in => ["unstable", "stable"]

  option :sensu_version,
  :short => "-v SENSU_VERSION",
  :long => "--version SENSU_VERSION",
  :description => "The version of Sensu",
  :required => true

  option :build_number,
  :short => "-n BUILD_NUMBER",
  :long => "--build-number BUILD_NUMBER",
  :description => "The version of Sensu",
  :required => true

  option :help,
  :short => "-h",
  :long => "--help",
  :description => "Show this message",
  :on => :tail,
  :boolean => true,
  :show_options => true,
  :exit => 0
end

def fetch_artifacts(artifacts)
  puts "fetching artifacts..."

  # connect to s3 here
  @s3 ||= Aws::S3::Client.new(:region => ENV["AWS_REGION"])
  artifacts.each do |source, destination|
    destination_dir = File.dirname(destination)
    FileUtils.mkdir_p(destination_dir)

    # copy from s3 here
    if File.exist?(destination)
      puts "Skipping #{source} as #{destination} already exists"
    else
      begin
        puts "Downloading sensu-omnibus-artifacts/#{source} => #{destination}"
        resp = @s3.get_object(
          :response_target => destination,
          :bucket => 'sensu-omnibus-artifacts',
          :key => source
        )
        puts resp.metadata
      rescue Aws::S3::Errors::NoSuchKey => e
        puts "Failed to retrieve #{source}: #{e}"
      end
    end
  end
end

def fix_permissions(platforms)
  platforms.each_pair do |name, data|
    base_path = data["base_path"]
    raise "platform #{name} does not specify repository base_path" if base_path.nil?
    destination_owner = File.stat(base_path).uid
    destination_group = File.stat(base_path).gid
    puts "fixing permissions for #{base_path} with uid #{destination_owner}, gid #{destination_group}"
    permissions_result = FileUtils.chown_R(destination_owner, destination_group, base_path, :verbose => true)
    puts permissions_result
  end
end

def run_commands(commands)
  puts "running commands..."
  commands.each do |command|
    puts command
    cmd = Mixlib::ShellOut.new(command)
    cmd.run_command
  end
  puts
end

cli = SensuPackageCLI.new
cli.parse_options
channel = cli.config[:channel]
sensu_version = cli.config[:sensu_version]
build_number = cli.config[:build_number]
base_path = "/srv"
artifacts = {}
commands = []

PLATFORMS.each do |name, data|
  data["versions"].each do |version, details|
    details["architectures"].each do |architecture|
      source_path = case name
      when "debian", "ubuntu", "el"
        if architecture == "i386"
          File.join(name, version, "i686")
        else
          File.join(name, version, architecture)
        end
      else
        File.join(name, version, architecture)
      end

      destination_path = nil

      case name
      when "debian", "ubuntu"
        filename = "sensu_#{sensu_version}-#{build_number}_#{architecture == "x86_64" ? "amd64" : "i386" }.deb"
        codename = details["codename"]
        destination_path = File.join("/tmp", "apt", codename, channel, filename)
      when "el"
        filename = "sensu-#{sensu_version}-#{build_number}.el#{version}.#{architecture}.rpm"
        destination_path = File.join(base_path, "createrepo", channel, version, architecture, filename)
      when "windows"
        filename = "sensu-#{sensu_version}-#{build_number}-#{architecture == "x86_64" ? "x64" : "x86" }.msi"
        destination_path = File.join(base_path, "msi", channel, version, filename)
      when "freebsd"
        filename = "sensu-#{sensu_version}_#{build_number}.txz"
        abi = "FreeBSD:#{version}:#{architecture}"
        destination_path = File.join(base_path, "freebsd", channel, abi, "sensu", filename)
      else
        raise "unsupported platform"
      end

      source_path = File.join(source_path, filename, filename)
      artifacts[source_path] = destination_path

      case name
      when "debian", "ubuntu"
        codename = details["codename"]
        cwd = File.join(base_path, "freight")
        manager = "apt"
        commands << "cd #{cwd} && sudo -u freight -- freight add -c /srv/freight/freight.conf #{destination_path} apt/#{codename}/#{channel}"
      end
    end
  end
end

# repository re-indexing
PLATFORMS.each do |platform, data|
  case platform
  when "debian", "ubuntu"
    cwd = File.join(base_path, "freight")
    commands << "cd #{cwd} && sudo -H -u freight -- freight cache -c /srv/freight/freight.conf"
  when "el"
    data["versions"].each do |version, details|
      details["architectures"].each do |architecture|
        cwd = File.join(base_path, "createrepo", channel, version, architecture)
        commands << "cd #{cwd} && sudo -u createrepo -- createrepo -s sha ."
      end
    end
  when "freebsd"
    data["versions"].each do |version, details|
      details["architectures"].each do |architecture|
        abi = "FreeBSD:#{version}:#{architecture}"
        cwd = File.join(base_path, "freebsd", abi, channel)
        commands << "cd #{cwd} && pkg repo ."
      end
    end
  end
end

fetch_artifacts(artifacts)
fix_permissions(PLATFORMS)
run_commands(commands)
