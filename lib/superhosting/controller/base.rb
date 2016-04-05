module Superhosting
  module Controller
    class Base < Base
      def repair
        container_controller = self.get_controller(Container)
        container_controller.index.each do |container_name, hash_of_mappers|
          if hash_of_mappers[:state_mapper].value != 'up'
            container_controller.reconfigure(name: container_name).net_status_ok!
          else
            container_controller._each_site(name: container_name) do |controller, name, state|
              controller.reconfigure(name: name).net_status_ok! if state != 'up'
            end
          end
        end
      end
    end
  end
end