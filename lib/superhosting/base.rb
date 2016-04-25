module Superhosting
  class Base
    include Helpers

    attr_reader :config, :lib

    def initialize(**kwargs)
      config_path = kwargs[:config_path] || '/etc/sx'
      lib_path = kwargs[:lib_path] || '/var/sx'

      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper.new(config_path)
      @lib = PathMapper.new(lib_path)
      Thread.current[:logger] ||= kwargs[:logger]
      Thread.current[:debug] ||= kwargs[:debug]
      Thread.current[:dry_run] ||= kwargs[:dry_run]

      @docker_api = kwargs[:docker_api] || DockerApi.new(socket: @config.f('docker_socket', default: nil))
    end

    def base_controller_options
      {
        config_path: @config_path.to_s,
        lib_path: @lib_path.to_s,
        docker_api: @docker_api
      }
    end

    def get_controller(controller, **kwargs)
      controller.new(**base_controller_options.merge!(kwargs))
    end
  end
end
