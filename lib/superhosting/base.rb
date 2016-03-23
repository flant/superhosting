module Superhosting
  class Base
    include Helpers

    attr_reader :config, :lib

    def initialize(config_path: '/etc/sx', lib_path: '/var/sx', logger: nil, docker_socket: nil, docker_api: nil, **kwargs)
      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper.new(config_path)
      @lib = PathMapper.new(lib_path)
      Thread.current[:superhosting_logger] = logger

      @docker_api = docker_api || DockerApi.new(socket: docker_socket)
    end

    def get_base_controller_options
      {
          config_path: @config_path.to_s,
          lib_path: @lib_path.to_s,
          logger: logger,
          docker_api: @docker_api
      }
    end

    def get_controller(controller, **kwargs)
      controller.new(**self.get_base_controller_options.merge!(kwargs))
    end
  end
end
