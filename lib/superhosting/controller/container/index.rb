module Superhosting
  module Controller
    class Container
      class << self; attr_accessor :index end

      def initialize(**kwargs)
        super
        index
      end

      class IndexItem
        attr_reader :name, :controller

        def initialize(name:, controller:)
          @name = name
          @controller = controller
        end

        def etc_mapper
          @etc_mapper ||= PathMapper.new(controller.config.path.join('containers', name))
        end

        def lib_mapper
          PathMapper.new(controller.lib.path.join('containers', name))
        end

        def web_mapper
          PathMapper.new("/web/#{name}")
        end

        def mapper
          @mapper ||= begin
            mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)
            mapper.erb_options = { container: mapper, etc: controller.config, lib: controller.lib }
            mapper
          end
        end

        def inheritance_mapper
          @inheritance_mapper ||= begin
            model_mapper = controller.config.models.f(model_name)
            mapper.etc_mapper = MapperInheritance::Model.set_inheritance(model_mapper, etc_mapper)
            mapper.erb_options = { container: mapper, etc: controller.config, lib: controller.lib }
            mapper
          end
        end

        def mux_mapper
          @mux_mapper ||= begin
            if (mux_file_mapper = mapper.mux).file?
              mux_name = mux_file_mapper.value
              mux_controller = controller.controller(Mux)
              mux_controller.existing_validation(name: mux_name).net_status_ok!
              mux_controller.index[mux_name].mapper
            else
              plug = PathMapper.new("/tmp/sx/null/#{SecureRandom.uuid}")
              CompositeMapper::Mux.new(etc_mapper: plug, lib_mapper: plug)
            end
          end
        end

        def state_mapper
          lib_mapper.state
        end

        def model_name
          etc_mapper.f('model', default: controller.config.default_model).value
        end
      end

      def index
        self.class.index ||= with_profile('container_index') { reindex }
      end

      def reindex
        self.class.index = {}
        @config.containers.grep_dirs.each { |mapper| reindex_container(name: mapper.name) }
        self.class.index
      end

      def reindex_container(name:)
        self.class.index ||= {}

        index_item = IndexItem.new(name: name, controller: self)

        if index_item.etc_mapper.nil? and index_item.lib_mapper.nil?
          self.class.index.delete(name)
          return
        end

        self.class.index[name] = index_item
      end
    end
  end
end
