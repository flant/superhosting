module Superhosting
  class Base
    include Helpers

    attr_reader :config, :lib

    def initialize(config_path: '/etc/sx', lib_path: '/var/lib/sx', logger: nil, docker_socket: nil, docker_api: nil, **kwargs)
      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper.new(config_path)
      @lib = PathMapper.new(lib_path)
      @logger = logger

      @docker_api = docker_api || DockerApi.new(socket: docker_socket)
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
      {} # net_status_ok
    end

    def command!(*command_args)
      cmd = run_command(*command_args)
      if cmd.status.success?
        msg = [cmd.stdout, cmd.stderr].delete_if { |str| str.empty? }.join("\n")
        debug(msg) unless msg.empty?
        {} # net_status_ok
      else
        raise NetStatus::Exception.new(error: :error, code: :command_with_error, data: { error: [cmd.stdout, cmd.stderr].join("\n") })
      end
    end

    def command(*command_args)
      cmd = run_command(*command_args)
      msg = [cmd.stdout, cmd.stderr].delete_if { |str| str.empty? }.join("\n")
      debug(msg) unless msg.empty?
      {} # net_status_ok
    end

    def get_base_controller_options
      {
          config_path: @config_path.to_s,
          lib_path: @lib_path.to_s,
          logger: @logger,
          docker_api: @docker_api
      }
    end

    def get_controller(controller, **kwargs)
      controller.new(**self.get_base_controller_options.merge!(kwargs))
    end
  end
end
