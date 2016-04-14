module Superhosting
  module Controller
    class Mux
      attr_writer :index

      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
        self.index
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @@index ||= {}
        @container_controller._list.map do |container_name, data|
          container_mapper = @container_controller.index[container_name][:mapper]
          if (mux_mapper = container_mapper.mux).file?
            mux_name = mux_mapper.value
            if @container_controller.running_validation(name: container_name).net_status_ok?
              self.index_push(mux_name, container_name)
            else
              self.index_pop(mux_name, container_name)
            end
          end
        end
        @@index
      end

      def index_pop(mux_name, container_name)
        if self.index.key? mux_name
          self.index[mux_name].delete(container_name)
          self.index.delete(mux_name) if self.index[mux_name].empty?
        end
      end

      def index_push(mux_name, container_name)
        self.index[mux_name] ||= []
        self.index[mux_name] << container_name unless self.index[mux_name].include? container_name
      end
    end
  end
end