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

      def index
        self.class.index ||= reindex
      end

      def reindex
        self.class.index = {}
        @config.muxs.grep_dirs.each do |mux_mapper|
          next if mux_mapper.abstract?
          name = mux_mapper.name

          etc_mapper = MapperInheritance::Mux.set_inheritance(mux_mapper)
          mapper = CompositeMapper::Mux.new(etc_mapper: etc_mapper, lib_mapper: @lib.muxs.f(name))
          mapper.erb_options = { mux: mapper }

          self.class.index[name] ||= { containers: [], mapper: mapper, state_mapper: mapper.lib.state }
        end

        @container_controller.index.each do |container_name, _data|
          container_index = @container_controller.index[container_name]
          next unless (mux_mapper = container_index[:mapper].mux).file?
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
        self.class.index[name][:containers]
      end

      def index_pop_container(name, container_name)
        index_mux_containers(name: name).delete(container_name)
      end

      def index_push_container(name, container_name)
        index_mux_containers(name: name) << container_name unless self.class.index[name][:containers].include? container_name
      end
    end
  end
end
