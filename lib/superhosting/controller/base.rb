module Superhosting
  module Controller
    class Base < Base
      def repair
        container_controller = controller(Container)
        container_controller.index.each do |container_name, index_item|
          if index_item.state_mapper.value != 'up'
            container_controller.reconfigure(name: container_name).net_status_ok!
          else
            container_controller._each_site(name: container_name) do |controller, name, state|
              controller.reconfigure(name: name).net_status_ok! if state != 'up'
            end
          end
        end
      end

      def update
        container_controller = controller(Container)
        mux_controller = controller(Mux)
        mux_index = mux_controller.index
        containers = container_controller.index.keys
        mux_index.keys.each do |mux_name|
          mux_controller.update(name: mux_name)
          containers -= mux_controller.index_mux_containers(name: mux_name)
        end
        containers.each { |container| container_controller.update(name: container) }
        {}
      end
    end
  end
end
