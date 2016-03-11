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
          if (resp = @container_controller.list).net_status_ok?
            containers = resp[:data]
            container_users = containers.map do |c_name|
              unless @user_controller._get(name: "#{c_name}_admin_#{@admin_name}").nil?
                { container: c_name, user: "#{c_name}_admin_#{@admin_name}" }
              end
            end.compact

            { data: container_users }
          else
            resp
          end
        end

        def add(name:)
          admin_name = "admin_#{@admin_name}"

          if (resp = @container_controller.existing_validation(name: name)).net_status_ok? and
              (resp = @user_controller.not_existing_validation(name: admin_name, container_name: name)).net_status_ok?
            user, encrypted_password = @admin_passwd.split(':')
            if (resp = @user_controller._add(name: admin_name, container_name: name, shell: '/bin/bash')).net_status_ok?
              encrypted_password.empty? ? {} : @user_controller._update_password(name: "#{name}_#{admin_name}", encrypted_password: encrypted_password)
            else
              return resp
            end
          else
            resp
          end
        end

        def delete(name:)
          admin_name = "admin_#{@admin_name}"

          if !(resp = @container_controller.existing_validation(name: name)).net_status_ok?
            resp
          elsif @user_controller.existing_validation(name: admin_name, container_name: name).net_status_ok?
            @user_controller.delete(name: admin_name, container_name: name)
          else
            self.debug("Admin '#{"#{name}_admin_#{@admin_name}"}' has already been deleted")
          end
        end

        def _containers_list
          if (resp = self.list).net_status_ok?
            containers = resp[:data].map {|elm| elm[:container] }
            { data: containers }
          else
            resp
          end
        end

        def _users_list
          if (resp = self.list).net_status_ok?
            users = resp[:data].map {|elm| elm[:user] }
            { data: users }
          else
            resp
          end
        end

        def _delete_all_users
          if (resp = self._containers_list).net_status_ok?
            containers = resp[:data]
            containers.each do |container_name|
              unless (resp = self.delete(name: container_name)).net_status_ok?
                return resp
              end
            end
            {}
          else
            resp
          end
        end
      end
    end
  end
end