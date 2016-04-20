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
          container_admins = self._list
          { data: container_admins }
        end

        def _list
          self._list_users.map do |user|
            { 'admin' => user[/(?<=#{@container_name}_admin_)(.*)/], 'user' => user }
          end
        end

        def add(name:)
          if (resp = @admin_controller.existing_validation(name: name)).net_status_ok?
            admin_container_controller = self.get_controller(Controller::Admin::Container, name: name)
            resp = admin_container_controller.add(name: @container_name)
          end
          resp
        end

        def delete(name:)
          if (resp = @admin_controller.existing_validation(name: name)).net_status_ok?
            admin_container_controller = self.get_controller(Controller::Admin::Container, name: name)
            resp = admin_container_controller.delete(name: @container_name)
          end
          resp
        end

        def _list_users
          users = @user_controller._group_get_users_names(name: @container_name)
          users.select {|user| user.start_with? "#{@container_name}_admin_" }
        end
      end
    end
  end
end