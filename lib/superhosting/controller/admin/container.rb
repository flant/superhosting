module Superhosting
  module Controller
    class Admin
      class Container < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @admin_name = name
          @user_controller = self.get_controller(User)
          @admin_controller = self.get_controller(Admin)
          @container_controller = self.get_controller(Controller::Container)
          @admin_passwd = @config.admins.f(@admin_name).passwd

          @admin_controller.existing_validation(name: @admin_name).net_status_ok!
        end

        def list
          { data: self._list }
        end

        def _list
          @container_controller._list.map do |container_info|
            container_name = container_info['name']
            unless @user_controller._get(name: "#{container_name}_admin_#{@admin_name}").nil?
              { 'container' => container_name, 'user' => "#{container_name}_admin_#{@admin_name}" }
            end
          end.compact
        end

        def add(name:)
          admin_name = "admin_#{@admin_name}"

          if (resp = @container_controller.available_validation(name: name)).net_status_ok? &&
             (resp = @user_controller.not_existing_validation(name: admin_name, container_name: name)).net_status_ok?
            user, encrypted_password = @admin_passwd.split(':')
            if (resp = @user_controller._add(name: admin_name, container_name: name, shell: '/bin/bash')).net_status_ok?
              resp = encrypted_password.nil? ? {} : @user_controller._update_password(name: "#{name}_#{admin_name}", encrypted_password: encrypted_password)
            end
          end
          resp
        end

        def delete(name:)
          admin_name = "admin_#{@admin_name}"

          if (resp = @container_controller.available_validation(name: name)).net_status_ok? &&
             (resp = @user_controller.existing_validation(name: admin_name, container_name: name)).net_status_ok?
            resp = @user_controller.delete(name: admin_name, container_name: name)
          end
          resp
        end

        def _containers_list
          self._list.map { |elm| elm['container'] }
        end

        def _users_list
          self._list.map { |elm| elm[:user] }
        end

        def _delete_all_users
          self._containers_list.each do |container_name|
            unless (resp = self.delete(name: container_name)).net_status_ok?
              return resp
            end
          end
          {}
        end
      end
    end
  end
end
