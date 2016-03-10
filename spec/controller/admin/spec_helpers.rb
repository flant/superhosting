module SpecHelpers
  module Controller
    module Admin
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def admin_controller
        @admin_controller ||= Superhosting::Controller::Admin.new
      end

      # methods

      def admin_add(**kwargs)
        admin_controller.add(**kwargs)
      end

      def admin_delete(**kwargs)
        admin_controller.delete(**kwargs)
      end

      def admin_list(**kwargs)
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

      def admin_container_list(**kwargs)
        admin_controller.container(name: @admin_name).list
      end

      # expectations

      def admin_add_exps(**kwargs)
        admin_name = kwargs[:name]
        config_mapper = admin_controller.config
        admins_mapper = config_mapper.admins
        admin_mapper = admins_mapper.f(admin_name)

        # /etc/sx/admins
        expect_dir(admins_mapper)
        expect_dir(admin_mapper)
        expect_file(admin_mapper.passwd)
      end

      def admin_passwd_exps(**kwargs)
        admin_name = kwargs[:name]
        config_mapper = admin_controller.config
        admins_mapper = config_mapper.admins
        admin_mapper = admins_mapper.f(admin_name)

        # /etc/sx/admins
        expect_in_file(admin_mapper.passwd, /#{admin_name}:(?!!)/)
      end

      def admin_delete_exps(**kwargs)
        admin_name = kwargs[:name]
        config_mapper = admin_controller.config
        admins_mapper = config_mapper.admins
        admin_mapper = admins_mapper.f(admin_name)

        # /etc/sx/admins
        not_expect_dir(admin_mapper)
      end

      def admin_container_add_exps(**kwargs)
        user_add_exps(name: "admin_#{@admin_name}")
        user_passwd_exps(name: "#{@container_name}_admin_#{@admin_name}")
      end

      def admin_container_delete_exps(**kwargs)
        user_delete_exps(name: "admin_#{@admin_name}")
      end

      # other

      def with_admin
        admin_add_with_exps(name: @admin_name, generate: true)
        yield @admin_name
        admin_delete_with_exps(name: @admin_name)
      end

      def with_admin_container
        with_container do |container_name|
          with_admin do |admin_name|
            admin_container_add(name: container_name)
            yield container_name, admin_name
            admin_container_delete(name: container_name)
          end
        end
      end

      included do
        before :each do
          @admin_name = "testA#{SecureRandom.hex[0..5]}"
        end

        after :all do
          run_command(["rm -rf /etc/sx/admins/test*"])
        end
      end
    end
  end
end
