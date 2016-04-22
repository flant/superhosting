module SpecHelpers
  module Helper
    module Base
      def controller
        @controller ||= Superhosting::Base.new
      end

      def config
        controller.config
      end

      def lib
        controller.lib
      end

      def etc
        PathMapper.new('/etc')
      end

      def web
        PathMapper.new('/web')
      end

      def site_web(container_name, site_name)
        container_web(container_name).f(site_name)
      end

      def container_web(container_name)
        web.f(container_name)
      end

      def site_etc(container_name, site_name)
        container_etc(container_name).sites.f(site_name)
      end

      def container_etc(container_name)
        config.containers.f(container_name)
      end

      def site_lib(container_name, site_name)
        container_lib(container_name).web.f(site_name)
      end

      def container_lib(container_name)
        lib.containers.f(container_name)
      end

      def site_aliases(container_name, site_name)
        container_lib(container_name).sites.f(site_name).aliases
      end

      def site_state(container_name, site_name)
        container_lib(container_name).sites.f(site_name).state
      end

      def container_state(container_name)
        container_lib(container_name).state
      end

      def cli(*args)
        with_thread_options = lambda do |&b|
          begin
            old_logger = Thread.current[:logger]
            old_dry_run = Thread.current[:debug]
            old_verbose = Thread.current[:verbose]
            b.call
          ensure
            Thread.current[:logger] = old_logger
            Thread.current[:debug] = old_dry_run
            Thread.current[:verbose] = old_verbose
          end
        end

        begin
          with_thread_options.call do
            Superhosting::Cli::Base.start(args)
          end
        rescue SystemExit => e
          raise unless e.status == 1
        rescue StandardError => e
          net_status = e.net_status.net_status_normalize
          $stderr.puts(net_status[:message] || [net_status[:error], net_status[:code]].compact.join(': '))
          raise
        end
      end

      def docker_api
        @docker_api ||= if @with_docker
                          Superhosting::DockerApi.new
                        else
                          docker_instance = instance_double('Superhosting::DockerApi')
                          allow(docker_instance).to receive(:method_missing) { |_method, *_args| true }
                          [:container_list, :grab_container_options].each { |m| allow(docker_instance).to receive(m) { |_options| [] } }
                          docker_instance
                        end
      end
    end
  end
end
