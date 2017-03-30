#!/usr/bin/env ruby
require "aws-sdk"
require "mixlib/cli"
require "mixlib/shellout"
require "highline/import"
require_relative "platforms"

class SensuPackageCLI
  include Mixlib::CLI

  option :project,
    :short => "-p PROJECT",
    :long => "--project PROJECT",
    :default => "sensu",
    :description => "the software project to use",
    :in => ["sensu", "uchiwa", "sensu-enterprise", "sensu-enterprise-dashboard"]

  option :channel,
    :short => "-c CHANNEL",
    :long => "--channel CHANNEL",
    :default => "unstable",
    :description => "The channel to use",
    :in => ["unstable", "stable"]

  option :project_version,
    :short => "-v PROJECT_VERSION",
    :long => "--version PROJECT_VERSION",
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

def fetch_artifacts(artifacts, bucket)
  puts "fetching artifacts..."

  # connect to s3 here
  @s3 ||= Aws::S3::Client.new(:region => ENV["AWS_REGION"])
  artifacts.each do |destination, source|
    destination_dir = File.dirname(destination)
    FileUtils.mkdir_p(destination_dir)

    # copy from s3 here
    if File.exist?(destination)
      puts "Skipping #{source} as #{destination} already exists"
    else
      begin
        puts "Downloading #{bucket}/#{source} => #{destination}"
        resp = @s3.get_object(
          :response_target => destination,
          :bucket => bucket,
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
project = cli.config[:project]
project_version = cli.config[:project_version]
build_number = cli.config[:build_number]
base_path = "/srv"
artifacts = {}
commands = []
bucket = nil
platforms = nil

if channel == "stable"
  exit unless HighLine.agree("\033[31m***WARNING*** Are you sure you want to push to the STABLE channel? (y/n)\033[0m")
end

case project
when "sensu-enterprise"
  platforms = ENTERPRISE_PLATFORMS
  bucket = "sensu-enterprise-artifacts"
when "sensu-enterprise-dashboard"
  platforms = ENTERPRISE_DASHBOARD_PLATFORMS
  bucket = "sensu-enterprise-artifacts"
else
  platforms = PLATFORMS
  bucket = "sensu-omnibus-artifacts"
end

platforms.each do |name, data|
  data["versions"].each do |version, details|
    codenames = if details.key?("codename")
      [details["codename"]].compact.flatten
    else
      [version]
    end
    codenames.each do |codename|
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

        filename, destination_path, metadata_filename, metadata_destination_path = nil, nil, nil, nil

        case name
        when "aix"
          filename = "#{project}-#{project_version}-#{build_number}.#{architecture}.bff"
          destination_path = File.join(base_path, "aix", channel, version, filename)
        when "debian", "ubuntu"
          filename = "#{project}_#{project_version}-#{build_number}_#{architecture == "x86_64" ? "amd64" : architecture }.deb"
          destination_path = File.join("/tmp", "apt", codename, filename)
        when "el"
          case project
          when "sensu-enterprise", "sensu-enterprise-dashboard"
            filename = "#{project}-#{project_version}-#{build_number}.#{architecture}.rpm"
          else
            filename = "#{project}-#{project_version}-#{build_number}.el#{version}.#{architecture}.rpm"
          end
          destination_path = File.join(base_path, "createrepo", channel, version, architecture, filename)
        when "mac_os_x"
          filename = "#{project}-#{project_version}-#{build_number}.dmg"
          destination_path = File.join(base_path, "osx", channel, version, architecture, filename)
        when "freebsd"
          filename = "#{project}-#{project_version}_#{build_number}.txz"
          abi = "FreeBSD:#{version}:#{architecture}"
          destination_path = File.join(base_path, "freebsd", channel, abi, project, filename)
        when "solaris2"
          case version
          when "5.10"
            filename = "#{project}-#{project_version}-#{build_number}.#{architecture}.solaris"
            destination_path = File.join(base_path, "solaris", "pkg", channel, version, filename)
          when "5.11"
            filename = "#{project}-#{project_version}-#{build_number}.#{architecture}.p5p"
            destination_path = File.join(base_path, "solaris", "ips", channel, version, filename)
          end
        when "windows"
          filename = "#{project}-#{project_version}-#{build_number}-#{architecture == "x86_64" ? "x64" : "x86" }.msi"
          destination_path = File.join(base_path, "msi", channel, version, filename)
          metadata_filename = [ filename, '.metadata.json' ].join
          metadata_destination_path = File.join(base_path, "msi", channel, version, metadata_filename)
        else
          raise "unsupported platform"
        end

        final_source_path = File.join(source_path, filename, filename)
        artifacts[destination_path] = final_source_path

        unless metadata_filename.nil?
          metadata_source_path = File.join(source_path, filename, metadata_filename)
          artifacts[metadata_destination_path] = metadata_source_path
        end

        case name
        when "debian", "ubuntu"
          apt_channel = channel == "stable" ? "main" : channel
          cwd = File.join(base_path, "freight")
          manager = "apt"
          commands << "cd #{cwd} && sudo -u freight -- freight add -c /srv/freight/freight.conf #{destination_path} apt/#{codename}/#{apt_channel}"
        end
      end
    end
  end
end

# repository re-indexing
platforms.each do |platform, data|
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

fetch_artifacts(artifacts, bucket)
fix_permissions(platforms)
run_commands(commands)
