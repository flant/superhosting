module SpecHelpers
  module Controller
    module Container
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def container_controller
        @container_controller ||= Superhosting::Controller::Container.new
      end

      # methods

      def container_add(**kwargs)
        container_controller.add(**kwargs)
      end

      def container_delete(**kwargs)
        container_controller.delete(**kwargs)
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
        model = config_mapper.default_model.value
        model_mapper = models_mapper.f(model)
        expect_dir(model_mapper)
        expect_file(model_mapper.docker_image)

        # /var/lib/sx
        expect_dir(container_lib_mapper)
        expect_dir(container_lib_mapper.configs)
        expect_file(container_lib_mapper.configs.f('etc-group'))
        expect_file(container_lib_mapper.configs.f('etc-passwd'))
        expect_dir(container_lib_mapper.supervisor)
        expect_dir(container_lib_mapper.web)

        # /web/
        expect_dir(web_mapper)
        expect_dir(web_mapper.f(container_name))
        expect_file_owner(web_mapper.f(container_name), container_name)

        # group / user
        expect_group(container_name)
        expect_user(container_name)
        expect_in_file(etc_mapper.passwd, /#{container_name}.*\/usr\/sbin\/nologin/)
        expect_in_file(container_lib_mapper.configs.f('etc-passwd'), /#{container_name}.*\/usr\/sbin\/nologin/)
        expect_in_file(container_lib_mapper.configs.f('etc-group'), /#{container_name}.*/)

        # docker.conf
        expect_file(etc_mapper.security.f('docker.conf'))
        expect_in_file(etc_mapper.security.f('docker.conf'), "@#{container_name} #{container_name}")

        # container
        expect(docker_api.container_info(container_name)).not_to be_nil
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

        # /var/lib/sx
        not_expect_dir(container_lib_mapper)

        # /web
        not_expect_dir(web_mapper.f(container_name))

        # group / user
        not_expect_group(container_name)
        not_expect_user(container_name)
        not_expect_in_file(etc_mapper.passwd, /#{container_name}.*\/usr\/sbin\/nologin/)

        # docker
        not_expect_in_file(etc_mapper.security.f('docker.conf'), "@#{container_name} #{container_name}")

        # container
        expect(docker_api.container_info(container_name)).to be_nil
      end

      def container_admin_add_exps(**kwargs)
        admin_container_add_exps
      end

      def container_admin_delete_exps(**kwargs)
        admin_container_delete_exps
      end

      # other

      def with_container
        container_add_with_exps(name: @container_name)
        yield @container_name
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

        after :all do
          run_command(["docker ps --filter 'name=test' -a | xargs docker stop"])
          run_command(["docker ps --filter 'name=test' -a | xargs docker rm"])

          Etc.passwd do |user|
            run_command(["userdel", user.name]) if user.name.start_with? 'test'
          end

          run_command(["rm -rf /etc/sx/containers/test*"])
          run_command(["rm -rf /var/lib/sx/containers/test*"])
          run_command(["rm -rf /web/test*"])
        end
      end
    end
  end
end
