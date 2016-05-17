module SpecHelpers
  module Controller
    module Admin
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def admin_controller
        @admin_controller ||= Superhosting::Controller::Admin.new(docker_api: docker_api)
      end

      # methods

      def admin_add(**kwargs)
        admin_controller.add(**kwargs)
      end

      def admin_delete(**kwargs)
        admin_controller.delete(**kwargs)
      end

      def admin_list(**_kwargs)
        admin_controller.list
      end

      def admin_passwd(**kwargs)
        admin_controller.passwd(**kwargs)
      end

      def admin_container_add(**kwargs)
        admin_controller.container(name: @admin_name).add(**kwargs)
      end

      def admin_container_delete(**kwargs)
        admin_controller.container(name: @admin_name).delete(**kwargs)
      end

      def admin_container_list(**_kwargs)
        admin_controller.container(name: @admin_name).list
      end

      # expectations

      def admin_base(**kwargs)
        name = kwargs[:name]
        admins_mapper = lib.admins
        mapper = admins_mapper.f(name)

        yield name, mapper, admins_mapper
      end

      def admin_add_exps(**kwargs)
        admin_base(**kwargs) do |name, mapper, admins_mapper|
          # index
          expect(admin_controller.index).to include(name)

          # /etc/sx/admins
          expect_dir(admins_mapper)
          expect_dir(mapper)
          expect_file(mapper.passwd)
        end
      end

      def admin_passwd_exps(**kwargs)
        admin_base(**kwargs) do |name, mapper, _admins_mapper|
          # /etc/sx/admins
          expect_in_file(mapper.passwd, /#{name}:(?!!)/)
        end
      end

      def admin_delete_exps(**kwargs)
        admin_base(**kwargs) do |name, mapper, _admins_mapper|
          # index
          expect(admin_controller.index).to_not include(name)

          # /etc/sx/admins
          etc_passwd_mapper = etc.passwd
          not_expect_dir(mapper)
          not_expect_in_file(etc_passwd_mapper, /_admin_#{name}/)
        end
      end

      def admin_container_add_exps(**kwargs)
        user_add_exps(name: "admin_#{@admin_name}", container_name: kwargs[:name])
        user_passwd_exps(name: "admin_#{@admin_name}", container_name: kwargs[:name])
      end

      def admin_container_delete_exps(**kwargs)
        user_delete_exps(name: "admin_#{@admin_name}", container_name: kwargs[:name])
      end

      # other

      def with_admin(**kwargs, &b)
        with_base('admin', default: { name: @admin_name, generate: true }, **kwargs, &b)
      end

      def with_admin_container(**kwargs, &b)
        with_container do |container_name|
          with_admin do |admin_name|
            with_base('admin_container', default: { name: container_name }, to_yield: [container_name, admin_name], **kwargs, &b)
          end
        end
      end

      included do
        before :each do
          @admin_name = "tA#{SecureRandom.hex[0..5]}"
        end

        after :each do
          with_logger(logger: false) do
            command('rm -rf /var/sx/admins/test*')
            admin_controller.reindex
          end
        end
      end
    end
  end
end
