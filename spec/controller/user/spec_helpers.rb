module SpecHelpers
  module Controller
    module User
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def user_controller
        @user_controller ||= Superhosting::Controller::User.new
      end

      # methods

      def user_add(**kwargs)
        user_controller.add(**kwargs)
      end

      def user_delete(**kwargs)
        user_controller.delete(**kwargs)
      end

      def user_list(**kwargs)
        user_controller.list(**kwargs)
      end

      def user_passwd(**kwargs)
        user_controller.passwd(**kwargs)
      end

      def user_change(**kwargs)
        user_controller.change(**kwargs)
      end

      # expectations

      def user_base(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        container_lib_mapper = self.container_lib(container_name)
        name = "#{container_name}_#{kwargs[:name] || @user_name}"

        yield name, container_name, container_lib_mapper
      end

      def user_add_exps(**kwargs)
        self.user_base(**kwargs) do |name, container_name, container_lib_mapper|
          # group / user
          shell = kwargs[:shell] || kwargs[:ftp_only] ?  '/usr/sbin/nologin' : '/bin/bash'
          expect_user(name)
          expect_in_file(self.etc.passwd, /#{name}.*#{shell}/)
          expect_in_file(container_lib_mapper.config.f('etc-passwd'), /#{name}.*#{shell}/)
        end
      end

      def user_delete_exps(**kwargs)
        self.user_base(**kwargs) do |name, container_name, container_lib_mapper|
          # group / user
          not_expect_user(name)
          not_expect_in_file(self.etc.passwd, /#{name}/)
          not_expect_in_file(container_lib_mapper.config.f('etc-passwd'), /#{name}.*/)
        end
      end

      def user_passwd_exps(**kwargs)
        self.user_base(**kwargs) do |name, container_name, container_lib_mapper|
          # /etc/shadow
          expect_in_file(self.etc.shadow, /#{name}:(?!!)/)
        end
      end

      def user_change_exps(**kwargs)
        user_add_exps(kwargs)
      end

      # other

      def with_user(**kwargs, &b)
        self.with_base('user', default: { name: @user_name, container_name: @container_name },
                       to_delete: { name: @user_name, container_name: @container_name }, **kwargs, &b)
      end

      included do
        before :each do
          @user_name = "testU#{SecureRandom.hex[0..5]}"
        end
      end
    end
  end
end
