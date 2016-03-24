module SpecHelpers
  module Controller
    module Container
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def container_controller
        @container_controller ||= Superhosting::Controller::Container.new(docker_api: docker_api, logger: logger)
      end

      # methods

      def container_add(**kwargs)
        container_controller.add(**kwargs)
      end

      def container_delete(**kwargs)
        container_controller.delete(**kwargs)
      end

      def container_reconfig(**kwargs)
        container_controller.reconfig(**kwargs)
      end

      def container_list(**kwargs)
        container_controller.list
      end

      def container_admin_add(**kwargs)
        container_controller.admin(name: @container_name).add(**kwargs)
      end

      def container_admin_delete(**kwargs)
        container_controller.admin(name: @container_name).delete(**kwargs)
      end

      def container_admin_list(**kwargs)
        container_controller.admin(name: @container_name).list
      end

      # expectations

      def container_add_exps(**kwargs)
        container_name = kwargs[:name]
        model_name = kwargs[:model]
        config_mapper = container_controller.config
        lib_mapper = container_controller.lib
        models_mapper = config_mapper.models
        container_mapper = config_mapper.containers.f(container_name)
        container_lib_mapper = lib_mapper.containers.f(container_name)
        web_mapper = PathMapper.new('/web')
        etc_mapper = PathMapper.new('/etc')

        # /etc/sx
        expect_dir(container_mapper)
        expect_file(config_mapper.default_model)
        expect_dir(models_mapper)

        # /etc/sx/models
        if model_name.nil?
          model_name = config_mapper.default_model
        else
          expect_file(container_mapper.model)
        end
        model_mapper = models_mapper.f(model_name)
        expect_dir(model_mapper)
        self.model_exps(:"container_add_#{model_name}_exps", **kwargs)

        # /var/sx
        expect_dir(container_lib_mapper)
        expect_dir(container_lib_mapper.config)
        expect_file(container_lib_mapper.config.f('etc-group'))
        expect_file(container_lib_mapper.config.f('etc-passwd'))
        expect_dir(container_lib_mapper.web)

        # /web/
        expect_dir(web_mapper)
        expect_dir(web_mapper.f(container_name))
        expect_file_owner(web_mapper.f(container_name), container_name)

        # group / user
        expect_group(container_name)
        expect_user(container_name)
        expect_in_file(etc_mapper.passwd, /#{container_name}.*\/usr\/sbin\/nologin/)
        expect_in_file(container_lib_mapper.config.f('etc-passwd'), /#{container_name}.*\/usr\/sbin\/nologin/)
        expect_in_file(container_lib_mapper.config.f('etc-group'), /#{container_name}.*/)

        # docker.conf
        expect_file(etc_mapper.security.f('docker.conf'))
        expect_in_file(etc_mapper.security.f('docker.conf'), "@#{container_name} #{container_name}")

        # container
        expect(docker_api.container_running?(container_name)).to be_truthy
      end

      def container_delete_exps(**kwargs)
        container_name = kwargs[:name]
        config_mapper = container_controller.config
        lib_mapper = container_controller.lib
        container_mapper = config_mapper.containers.f(container_name)
        container_lib_mapper = lib_mapper.containers.f(container_name)
        web_mapper = PathMapper.new('/web')
        etc_mapper = PathMapper.new('/etc')

        # /etc/sx
        not_expect_dir(container_mapper)

        # model
        model_name = container_mapper.f('model', default: config_mapper.default_model)
        self.model_exps(:"container_delete_#{model_name}_exps", **kwargs)

        # /var/sx
        not_expect_dir(container_lib_mapper)

        # /web
        not_expect_dir(web_mapper.f(container_name))

        # group / user
        not_expect_group(container_name)
        not_expect_user(container_name)
        not_expect_in_file(etc_mapper.passwd, /#{container_name}:.*\/usr\/sbin\/nologin/)

        # docker
        not_expect_in_file(etc_mapper.security.f('docker.conf'), "@#{container_name} #{container_name}")

        # container
        expect(docker_api.container_not_exists?(container_name)).to be_truthy
      end

      def container_admin_add_exps(**kwargs)
        admin_container_add_exps
      end

      def container_admin_delete_exps(**kwargs)
        admin_container_delete_exps
      end

      def container_add_fcgi_m_exps(**kwargs)
        container_name = kwargs[:name]
        lib_mapper = container_controller.lib
        container_lib_mapper = lib_mapper.containers.f(container_name)
        container_web_mapper = PathMapper.new('/web').f(container_name)

        # /var/sx
        config_supervisord = container_lib_mapper.config.supervisor.f('supervisord.conf')
        expect_file(config_supervisord)
        expect_in_file(config_supervisord, "file=/web/#{container_name}/supervisor.sock")

        # /web
        expect_dir(container_web_mapper.supervisor)
        expect_dir(container_web_mapper.logs.supervisor)
      end

      def container_delete_fcgi_m_exps(**kwargs)
        container_name = kwargs[:name]
        lib_mapper = container_controller.lib
        container_lib_mapper = lib_mapper.containers.f(container_name)
        container_web_mapper = PathMapper.new('/web').f(container_name)

        # /var/sx
        config_supervisord = container_lib_mapper.supervisor.f('supervisord.conf')
        not_expect_file(config_supervisord)

        # /web
        not_expect_dir(container_web_mapper.supervisor)
        not_expect_dir(container_web_mapper.logs.supervisor)
      end

      # other

      def with_container(**kwargs)
        container_add_with_exps(name: @container_name, **kwargs)
        yield @container_name if block_given?
        container_delete_with_exps(name: @container_name)
      end

      def with_container_admin
        with_container do |container_name|
          with_admin do |admin_name|
            container_admin_add_with_exps(name: admin_name)
            yield container_name, admin_name
            container_admin_delete_with_exps(name: admin_name)
          end
        end
      end

      included do
        before :each do
          @container_name = "testC#{SecureRandom.hex[0..5]}"
        end

        after :each do
          command("docker ps --filter 'name=test' -a | xargs docker stop")
          command("docker ps --filter 'name=test' -a | xargs docker rm")

          Etc.passwd do |user|
            command("userdel #{user.name}") if user.name.start_with? 'test'
          end

          command("rm -rf /etc/sx/containers/test*")
          command("rm -rf /var/sx/containers/test*")
          command("rm -rf /web/test*")
          command("rm -rf /etc/postfix/postfwd.cf.d/test*")
        end
      end
    end
  end
end
