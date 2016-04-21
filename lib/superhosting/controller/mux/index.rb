module Superhosting
  module Controller
    class Mux
      class << self; attr_accessor :index end
      attr_writer :index

      def initialize(**kwargs)
        super
        @container_controller = get_controller(Container)
        index
      end

      def index
        self.class.index ||= reindex
      end

      def reindex
        self.class.index ||= {}
        @container_controller.index.each do |container_name, data|
          container_mapper = @container_controller.index[container_name][:mapper]
          next unless (mux_mapper = container_mapper.mux).file?
          mux_name = mux_mapper.value
          if @container_controller.running_validation(name: container_name).net_status_ok?
            index_push(mux_name, container_name)
          else
            index_pop(mux_name, container_name)
          end
        end
        self.class.index
      end

      def index_pop(mux_name, container_name)
        if self.class.index.key? mux_name
          self.class.index[mux_name].delete(container_name)
          self.class.index.delete(mux_name) if self.class.index[mux_name].empty?
        end
      end

      def index_push(mux_name, container_name)
        self.class.index[mux_name] ||= []
        self.class.index[mux_name] << container_name unless self.class.index[mux_name].include? container_name
      end
    end
  end
end
