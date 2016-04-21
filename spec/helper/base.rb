module SpecHelpers
  module Helper
    module Base
      def controller
        @controller ||= Superhosting::Base.new
      end

      def config
        self.controller.config
      end

      def lib
        self.controller.lib
      end

      def etc
        PathMapper.new('/etc')
      end

      def web
        PathMapper.new('/web')
      end

      def site_web(container_name, site_name)
        self.container_web(container_name).f(site_name)
      end

      def container_web(container_name)
        self.web.f(container_name)
      end

      def site_etc(container_name, site_name)
        self.container_etc(container_name).sites.f(site_name)
      end

      def container_etc(container_name)
        self.config.containers.f(container_name)
      end

      def site_lib(container_name, site_name)
        self.container_lib(container_name).web.f(site_name)
      end

      def container_lib(container_name)
        self.lib.containers.f(container_name)
      end

      def site_aliases(container_name, site_name)
        self.container_lib(container_name).sites.f(site_name).aliases
      end

      def site_state(container_name, site_name)
        self.container_lib(container_name).sites.f(site_name).state
      end

      def container_state(container_name)
        self.container_lib(container_name).state
      end

      def cli(*args)
        def with_thread_options
          old_logger = Thread.current[:logger]
          old_dry_run = Thread.current[:debug]
          old_verbose = Thread.current[:verbose]
          yield
        ensure
          Thread.current[:logger] = old_logger
          Thread.current[:debug] = old_dry_run
          Thread.current[:verbose] = old_verbose
        end

        begin
          with_thread_options do
            Superhosting::Cli::Base.start(args)
          end
        rescue Exception => e
          net_status = e.net_status.net_status_normalize
          $stderr.puts(net_status[:message] || [net_status[:error], net_status[:code]].compact.join(": "))
          raise
        end
      end

      def docker_api
        @docker_api ||= if @with_docker
          Superhosting::DockerApi.new
        else
          docker_instance = instance_double('Superhosting::DockerApi')
          allow(docker_instance).to receive(:method_missing) { |method, *args, &block| true }
          [:container_list, :grab_container_options].each { |m| allow(docker_instance).to receive(m) { |options| [] } }
          docker_instance
        end
      end
    end
  end
end