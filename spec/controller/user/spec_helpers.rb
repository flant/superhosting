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

      def user_add_exps(**kwargs)
        lib_mapper = user_controller.lib
        container_name = kwargs[:container_name] || @container_name
        user_name = "#{container_name}_#{kwargs[:name]}"
        container_lib_mapper = lib_mapper.containers.f(container_name)
        etc_mapper = PathMapper.new('/etc')

        shell = kwargs[:ftp_only] ? '/usr/sbin/nologin' : '/bin/bash'

        # group / user
        expect_user(user_name)
        expect_in_file(etc_mapper.passwd, /#{user_name}.*#{shell}/)
        expect_in_file(container_lib_mapper.configs.f('etc-passwd'), /#{user_name}.*#{shell}/)
      end

      def user_delete_exps(**kwargs)
        lib_mapper = user_controller.lib
        container_name = kwargs[:container_name] || @container_name
        user_name = "#{container_name}_#{kwargs[:name]}"
        container_lib_mapper = lib_mapper.containers.f(container_name)
        etc_mapper = PathMapper.new('/etc')

        # group / user
        not_expect_user(user_name)
        not_expect_in_file(etc_mapper.passwd, /#{user_name}/)
        not_expect_in_file(container_lib_mapper.configs.f('etc-passwd'), /#{user_name}.*/)
      end

      def user_passwd_exps(**kwargs)
        user_name = kwargs[:name]
        etc_mapper = PathMapper.new('/etc')

        # /etc/shadow
        expect_in_file(etc_mapper.shadow, /#{user_name}:(?!!)/)
      end

      def user_change_exps(**kwargs)
        user_add_exps(kwargs)
      end

      # other

      def with_user
        user_add_with_exps(name: @user_name, container_name: @container_name)
        yield @user_name
        user_delete_with_exps(name: @user_name, container_name: @container_name)
      end

      included do
        before :each do
          @user_name = "testU#{SecureRandom.hex[0..5]}"
        end
      end
    end
  end
end
