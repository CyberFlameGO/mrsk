require "mrsk/commands/base"

class Mrsk::Commands::Accessory < Mrsk::Commands::Base
  attr_reader :accessory_config
  delegate :service_name, :image, :host, :port, :files, :env_args, :volume_args, :label_args, to: :accessory_config

  def initialize(config, name:)
    super(config)
    @accessory_config = config.accessory(name)
  end

  def run
    docker :run, 
      "--name", service_name,
      "-d",
      "--restart", "unless-stopped",
      "-p", port,
      *env_args,
      *volume_args,
      *label_args,
      image
  end

  def start
    docker :container, :start, service_name
  end

  def stop
    docker :container, :stop, service_name
  end

  def info
    docker :ps, *service_filter
  end

  def logs(since: nil, lines: nil, grep: nil)
    pipe \
      docker(:logs, service_name, (" --since #{since}" if since), (" -n #{lines}" if lines), "-t", "2>&1"),
      ("grep '#{grep}'" if grep)
  end

  def follow_logs(grep: nil)
    run_over_ssh pipe(
      docker(:logs, service_name, "-t", "-n", "10", "-f", "2>&1"),
      ("grep '#{grep}'" if grep)
    ).join(" "), host: host
  end

  def make_directory_for(local, remote)
    if Pathname.new(local).exist?
      [ :mkdir, "-p", Pathname.new(remote).dirname.to_s ]
    else
  def exec(*command, interactive: false)
    docker :exec,
      ("-it" if interactive),
      *env_args,
      *volume_args,
      service_name,
      *command
  end

  def run_exec(*command, interactive: false)
    docker :run,
      ("-it" if interactive),
      "--rm",
      *env_args,
      *volume_args,
      image,
      *command
  end

  def bash(host:)
    exec_over_ssh "bash", host: host
  end

      raise "Missing file: #{local}"
    end
  end

  def remove_files
    [ :rm, "-rf", service_name ]
  end

  def remove_container
    docker :container, :prune, "-f", *service_filter
  end

  def remove_image
    docker :image, :prune, "-a", "-f", *service_filter
  end

  private
    def exec_over_ssh(*command, host:)
      run_over_ssh run_exec(*command, interactive: true).join(" "), host: host
    end

    def service_filter
      [ "--filter", "label=service=#{service_name}" ]
    end
end