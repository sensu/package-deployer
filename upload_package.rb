#!/usr/bin/env ruby
require "aws-sdk"
require "mixlib/cli"

class PackageCLI
  include Mixlib::CLI

  option :project_version,
    :short => "-v PROJECT_VERSION",
    :long => "--version PROJECT_VERSION",
    :description => "The version of the project",
    :required => true

  option :build_number,
    :short => "-n BUILD_NUMBER",
    :long => "--build-number BUILD_NUMBER",
    :description => "The version of the project",
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

def upload_artifact(source, destination)
  puts "#{source} => #{destination}"
  # connect to s3 here
  @s3 ||= Aws::S3::Resource.new(:region => ENV["AWS_REGION"])

  # upload to s3 here
  unless File.exist?(source)
    puts "Warning! #{source} was not found."
  else
    begin
      puts "Uploading #{source} => sensu-omnibus-artifacts/#{destination}"

      obj = @s3.bucket("sensu-omnibus-artifacts").object(destination)
      obj.upload_file(source)
    rescue => e
      puts "Failed to upload #{source} => #{destination}: #{e}"
    end
  end
end

cli = PackageCLI.new
cli.parse_options
project = "uchiwa"
project_version = cli.config[:project_version]
build_number = cli.config[:build_number]
base_path = "/srv"

platforms = {
  "debian" => {
    "versions" => ["7", "8"]
  },
  "ubuntu" => {
    "versions" => ["12.04", "14.04", "16.04"]
  },
  "el" => {
    "versions" => ["5", "6", "7"]
  }
}

architectures = ["i686", "x86_64"]

platforms.each do |platform, platform_details|
  platform_details["versions"].each do |platform_version|
    architectures.each do |architecture|
      case platform
      when "debian", "ubuntu"
        base_path = "/srv/freight"
        deb_architecture = architecture == "x86_64" ? "amd64" : "i386"
        filename = "#{project}_#{project_version}-#{build_number}_#{deb_architecture}.deb"
        source_path = File.join(base_path, "lib", "apt", "sensu", "unstable", filename)
        destination_path = File.join(platform, platform_version, architecture, filename, filename)
        upload_artifact(source_path, destination_path)
      when "el"
        base_path = "/srv/createrepo"
        rpm_architecture = architecture == "i686" ? "i386" : "x86_64"
        source_filename = "#{project}-#{project_version}-#{build_number}.#{rpm_architecture}.rpm"
        destination_filename = "#{project}-#{project_version}-#{build_number}.el#{platform_version}.#{rpm_architecture}.rpm"
        source_path = File.join(base_path, "unstable", rpm_architecture, source_filename)
        destination_path = File.join(platform, platform_version, architecture, destination_filename, destination_filename)
        upload_artifact(source_path, destination_path)
      end
    end
  end
end
