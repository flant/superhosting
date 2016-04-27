module SpecHelpers
  module Controller
    module Container
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def container_controller
        @container_controller ||= Superhosting::Controller::Container.new(docker_api: docker_api)
      end

      # methods

      def container_add(**kwargs)
        container_controller.add(**kwargs)
      end

      def container_delete(**kwargs)
        container_controller.delete(**kwargs)
      end

      def container_reconfigure(**kwargs)
        container_controller.reconfigure(**kwargs)
      end

      def container_rename(**kwargs)
        container_controller.rename(**kwargs)
      end

      def container_update(**kwargs)
        container_controller.update(**kwargs)
      end

      def container_list(**_kwargs)
        container_controller.list
      end

      def container_model_name(**_kwargs)
        container_controller.model(name: @container_name).name
      end

      def container_model_tree(**_kwargs)
        container_controller.model(name: @container_name).tree
      end

      def container_inspect(**kwargs)
        container_controller.inspect(**kwargs)
      end

      def container_inheritance(**kwargs)
        container_controller.inheritance(**kwargs)
      end

      def container_options(**kwargs)
        container_controller.options(**kwargs)
      end

      def container_admin_add(**kwargs)
        container_controller.admin(name: @container_name).add(**kwargs)
      end

      def container_admin_delete(**kwargs)
        container_controller.admin(name: @container_name).delete(**kwargs)
      end

      def container_admin_list(**_kwargs)
        container_controller.admin(name: @container_name).list
      end

      # expectations

      def container_base(**kwargs)
        name = kwargs[:name]
        etc_mapper = container_etc(name)
        lib_mapper = container_lib(name)
        web_mapper = container_web(name)

        yield name, etc_mapper, lib_mapper, web_mapper
      end

      def container_add_exps(**kwargs)
        container_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper|
          model_name = kwargs[:model]
          models_mapper = config.models

          # /etc/sx
          expect_dir(etc_mapper)
          expect_file(config.default_model)
          expect_dir(models_mapper)

          # /etc/sx/models
          if model_name.nil?
            model_name = config.default_model
          else
            expect_file(etc_mapper.model)
          end
          model_mapper = models_mapper.f(model_name)
          expect_dir(model_mapper)
          model_exps(:"container_add_#{model_name}_exps", **kwargs)

          # /var/sx
          expect_file(lib_mapper.state)
          expect_dir(lib_mapper)
          expect_dir(lib_mapper.config)
          expect_file(lib_mapper.config.f('etc-group'))
          expect_file(lib_mapper.config.f('etc-passwd'))
          expect_dir(lib_mapper.web)
          expect_dir(lib_mapper.registry)
          expect_file(lib_mapper.registry.container)

          # /web/
          expect_dir(web)
          expect_dir(web_mapper)
          expect_file_owner(web_mapper, name)

          # group / user
          expect_group(name)
          expect_user(name)
          expect_in_file(etc.passwd, %r{#{name}.*\/usr\/sbin\/nologin})
          expect_in_file(lib_mapper.config.f('etc-passwd'), %r{#{name}.*\/usr\/sbin\/nologin})
          expect_in_file(lib_mapper.config.f('etc-group'), /#{name}.*/)

          # docker.conf
          expect_file(etc.security.f('docker.conf'))
          expect_in_file(etc.security.f('docker.conf'), "@#{name} #{name}")

          # container
          expect(docker_api.container_running?(name)).to be_truthy
        end
      end

      def container_delete_exps(**kwargs)
        container_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper|
          # /etc/sx
          not_expect_dir(etc_mapper)

          # model
          model_name = etc_mapper.f('model', default: config.default_model)
          model_exps(:"container_delete_#{model_name}_exps", **kwargs)

          # /var/sx
          not_expect_dir(lib_mapper)

          # /web
          not_expect_dir(web_mapper)

          # group / user
          not_expect_group(name)
          not_expect_user(name)
          not_expect_in_file(etc.passwd, %r{^#{name}:.*\/usr\/sbin\/nologin})

          # docker
          not_expect_in_file(etc.security.f('docker.conf'), "@#{name} #{name}")

          # container
          expect(docker_api.container_not_exists?(name)).to be_truthy
        end
      end

      def container_rename_exps(**kwargs)
        container_add_exps(name: kwargs.delete(:new_name))
        container_delete_exps(name: kwargs.delete(:name))
      end

      def container_admin_add_exps(**kwargs)
        admin_container_add_exps(container_name: kwargs[:name])
      end

      def container_admin_delete_exps(**kwargs)
        admin_container_delete_exps(container_name: kwargs[:name])
      end

      def container_add_fcgi_m_exps(**kwargs)
        container_base(**kwargs) do |name, _etc_mapper, lib_mapper, web_mapper|
          # /var/sx
          config_supervisord = lib_mapper.config.supervisor.f('supervisord.conf')
          expect_file(config_supervisord)
          expect_in_file(config_supervisord, "file=/web/#{name}/supervisor.sock")

          # /web
          expect_dir(web_mapper.supervisor)
          expect_dir(web_mapper.logs.supervisor)
        end
      end

      def container_delete_fcgi_m_exps(**kwargs)
        container_base(**kwargs) do |_name, _etc_mapper, lib_mapper, web_mapper|
          # /var/sx
          config_supervisord = lib_mapper.supervisor.f('supervisord.conf')
          not_expect_file(config_supervisord)

          # /web
          not_expect_dir(web_mapper.supervisor)
          not_expect_dir(web_mapper.logs.supervisor)
        end
      end

      # other

      def with_container(**kwargs, &b)
        with_base('container', default: { name: @container_name }, **kwargs, &b)
      end

      def with_container_admin(**kwargs, &b)
        with_container do |container_name|
          with_admin do |admin_name|
            with_base('container_admin', default: { name: admin_name }, to_yield: [container_name, admin_name], **kwargs, &b)
          end
        end
      end

      included do
        before :each do
          @container_name = "testC#{SecureRandom.hex[0..4]}"
        end

        after :each do
          with_logger(logger: false) do
            %w(new test).each do |prefix|
              PathMapper.new('/etc/sx/containers').grep(/#{prefix}/).each do |container_mapper|
                container_delete(name: container_mapper.name)
              end

              command("docker ps --filter 'name=#{prefix}' -a | xargs docker unpause")
              command("docker ps --filter 'name=#{prefix}' -a | xargs docker kill")
              command("docker ps --filter 'name=#{prefix}' -a | xargs docker rm")

              PathMapper.new('/etc/security/docker.conf').remove_line!(/@#{prefix}/)

              Etc.passwd { |user| command("userdel #{user.name}") if user.name.start_with? prefix }
              Etc.group { |group| command("groupdel #{group.name}") if group.name.start_with? prefix }

              command("rm -rf /etc/sx/containers/#{prefix}*")
              command("rm -rf /var/sx/containers/#{prefix}*")
              command("rm -rf /web/#{prefix}*")
              command("rm -rf /etc/postfix/postfwd.cf.d/#{prefix}*")
            end

            # mux
            command('docker unpause mux-test')
            command('docker kill mux-test')
            command('docker rm mux-test')
            command('docker unpause ctestmux')
            command('docker kill ctestmux')
            command('docker rm ctestmux')

            command('rm -rf /var/sx/containers/muxs/test')
          end
        end
      end
    end
  end
end
