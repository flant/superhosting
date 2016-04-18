module Superhosting
  class Base
    include Helpers

    attr_reader :config, :lib

    def initialize(config_path: '/etc/sx', lib_path: '/var/sx', logger: nil, docker_api: nil, dry_run: nil, debug: nil, **kwargs)
      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper.new(config_path)
      @lib = PathMapper.new(lib_path)
      Thread.current[:logger] ||= logger
      Thread.current[:debug] ||= debug
      Thread.current[:dry_run] ||= dry_run

      @docker_api = docker_api || DockerApi.new(socket: @config.f('docker_socket', default: nil))
    end

    def get_base_controller_options
      {
          config_path: @config_path.to_s,
          lib_path: @lib_path.to_s,
          docker_api: @docker_api,
      }
    end

    def get_controller(controller, **kwargs)
      controller.new(**self.get_base_controller_options.merge!(kwargs))
    end

    def without_inheritance(mapper:)
      inheritance = mapper.inheritance
      mapper.inheritance = []
      yield mapper, inheritance
    ensure
      mapper.inheritance = inheritance
    end

    def get_type(mapper:)
      case mapper.name
        when 'containers' then 'container'
        when 'web' then 'site'
        when 'models' then 'model'
        when 'muxs' then 'mux'
        else get_type(mapper: mapper.parent)
      end
    end

    def get_name(mapper:)
      case mapper.parent.name
        when 'containers', 'models', 'muxs' then mapper.name
        else get_name(mapper: mapper.parent)
      end
    end
  end
end
