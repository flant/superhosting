module Superhosting
  class Base
    include Helpers

    def initialize(config_path: '/etc/sx', lib_path: '/var/lib/sx', logger: nil, docker_socket: nil)
      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper.new(config_path)
      @lib = PathMapper.new(lib_path)
      @logger = logger

      @docker_api = DockerApi.new(socket: docker_socket)
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
    end

    def command!(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      if cmd.status.success?
        debug([cmd.stdout, cmd.stderr].join("\n"))
        cmd
      else
        raise NetStatus::Exception.new(error: :error, message: [cmd.stdout, cmd.stderr].join("\n"))
      end
    end

    def command(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      debug([cmd.stdout, cmd.stderr].join("\n"))
      cmd
    end
  end
end
