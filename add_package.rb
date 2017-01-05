#!/usr/bin/env ruby
require "aws-sdk"
require "mixlib/cli"
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
  artifacts.each do |source, destination|
    puts "#{source} => #{destination}"
  end
  puts
end

def run_commands(commands)
  puts "running commands..."
  commands.each do |command|
    puts command
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

PLATFORMS.each do |name, versions|
  versions.each do |version, details|
    details["architectures"].each do |architecture|
      source_path = File.join(name, version, architecture)
      destination_path = nil

      case name
      when "debian", "ubuntu"
        filename = "sensu_#{sensu_version}-#{build_number}_#{architecture}.deb"
        codename = details["codename"]
        destination_path = File.join("/tmp", "apt", codename, channel, filename)
      when "el"
        filename = "sensu-#{sensu_version}-#{build_number}.el#{version}.#{architecture}.rpm"
        destination_path = File.join(base_path, "createrepo", channel, version, architecture, filename)
      when "freebsd"
        filename = "sensu-#{sensu_version}_#{build_number}.txz"
        abi = "FreeBSD:#{version}:#{architecture}"
        destination_path = File.join(base_path, "freebsd", abi, channel, "sensu", filename)
      else
        raise "unsupported platform"
      end

      source_path = File.join(source_path, filename, filename)
      artifacts[source_path] = destination_path

      case name
      when "debian", "ubuntu"
        cwd = File.join(base_path, "freight")
        manager = "apt"
        commands << "cd #{cwd} && freight add -c /srv/freight/freight.conf #{source_path} apt/#{name}/#{channel}"
      end
    end
  end
end

# repository re-indexing
PLATFORMS.each do |platform, versions|
  case platform
  when "debian", "ubuntu"
    cwd = File.join(base_path, "freight")
    commands << "cd #{cwd} && freight cache -c /srv/freight/freight.conf"
  when "el"
    versions.each do |version, details|
      details["architectures"].each do |architecture|
        cwd = File.join(base_path, "createrepo", channel, version, architecture)
        commands << "cd #{cwd} && createrepo -s sha ."
      end
    end
  when "freebsd"
    versions.each do |version, details|
      details["architectures"].each do |architecture|
        abi = "FreeBSD:#{version}:#{architecture}"
        cwd = File.join(base_path, "freebsd", abi, channel)
        commands << "cd #{cwd} && pkg repo ."
      end
    end
  end
end

fetch_artifacts(artifacts)
run_commands(commands)
