module Superhosting
  module Controller
    class Container
      class Admin < Base
        def initialize(name:, **kwargs)
          super(kwargs)
          @container_name = name
          @user_controller = self.get_controller(User)
          @admin_controller = self.get_controller(Controller::Admin)
        end

        def list
          container_admins = self._list_users.map {|user| user[/(?<=#{@container_name}_admin_)(.*)/] }
          { data: container_admins }
        end

        def add(name:)
          if (resp = @admin_controller.existing_validation(name: name)).net_status_ok?
            admin_container_controller = self.get_controller(Controller::Admin::Container, name: name)
            admin_container_controller.add(name: @container_name)
          else
            resp
          end
        end

        def delete(name:)
          if @admin_controller.not_existing_validation(name: name).net_status_ok?
            self.debug("Admin '#{name}' has already been deleted")
          else
            admin_container_controller = self.get_controller(Controller::Admin::Container, name: name)
            admin_container_controller.delete(name: @container_name)
          end
        end

        def _list_users
          users = @user_controller._get_group_users(name: @container_name)
          users.select {|user| user.start_with? "#{@container_name}_admin_" }
        end
      end
    end
  end
end