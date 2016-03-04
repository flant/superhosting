require_relative '../spec_helpers'

module SpecHelpers
  module Controller
    module Container
      include SpecHelpers::Base

      def container_controller
        @container_controller ||= Superhosting::Controller::Container.new
      end

      def docker_api
        @docker_api ||= Superhosting::DockerApi.new
      end

      def container_add(**kwargs)
        container_controller.add(**kwargs)

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
        model = config_mapper.default_model
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
        owner = Etc.getgrnam(container_name)
        expect_file_owner(web_mapper.f(container_name), owner)

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
    end # Container
  end # Controller
end # SpecHelpers
