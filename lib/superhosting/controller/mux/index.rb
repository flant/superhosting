module Superhosting
  module Controller
    class Mux
      class << self; attr_accessor :index end
      attr_writer :index

      def initialize(**kwargs)
        super
        @container_controller = controller(Container)
        index
      end

      class IndexItem
        attr_accessor :name, :controller

        def initialize(name:, controller:)
          self.name = name
          self.controller = controller
        end

        def inheritance_mapper
          mapper
        end

        def mapper
          @mapper ||= begin
            mapper = CompositeMapper::Mux.new(etc_mapper: MapperInheritance::Mux.set_inheritance(controller.config.muxs.f(name)),
                                              lib_mapper: controller.lib.muxs.f(name))
            mapper.erb_options = { mux: mapper }
            mapper
          end
        end

        def containers
          @containers ||= []
        end

        def state_mapper
          mapper.lib.state
        end
      end

      def index
        self.class.index ||= reindex
      end

      def reindex
        self.class.index = {}
        @config.muxs.grep_dirs.each do |mux_mapper|
          next if mux_mapper.abstract?
          name = mux_mapper.name
          index_item = IndexItem.new(name: name, controller: self)
          self.class.index[name] ||= index_item
        end

        @container_controller.index.each do |container_name, container_index_item|
          next unless (mux_mapper = container_index_item.mapper.mux).file?
          name = mux_mapper.value
          if @container_controller.running_validation(name: container_name).net_status_ok?
            index_push_container(name, container_name)
          else
            index_pop_container(name, container_name)
          end
        end
        self.class.index
      end

      def index_mux_containers(name:)
        existing_validation(name: name).net_status_ok!
        self.class.index[name].containers
      end

      def index_pop_container(name, container_name)
        index_mux_containers(name: name).delete(container_name)
      end

      def index_push_container(name, container_name)
        index_mux_containers(name: name) << container_name unless self.class.index[name].containers.include? container_name
      end
    end
  end
end
