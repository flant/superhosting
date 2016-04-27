module Superhosting
  module Controller
    class Container
      class << self; attr_accessor :index end

      def initialize(**kwargs)
        super
        index
      end

      def index
        self.class.index ||= reindex
      end

      def reindex
        @config.containers.grep_dirs.each { |mapper| reindex_container(name: mapper.name) }
        self.class.index ||= {}
      end

      def reindex_container(name:)
        self.class.index ||= {}
        etc_mapper = @config.containers.f(name)
        web_mapper = PathMapper.new('/web').f(name)
        lib_mapper = @lib.containers.f(name)
        state_mapper = lib_mapper.state

        if etc_mapper.nil?
          self.class.index.delete(name)
          return
        end

        model_name = etc_mapper.f('model', default: @config.default_model).value
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(model_mapper).inheritors_mapper(etc_mapper)

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)

        etc_mapper.erb_options = { container: mapper, etc: @config, lib: @lib }
        mux_mapper = if (mux_file_mapper = etc_mapper.mux).file?
                       etc_mapper = MapperInheritance::Mux.new(@config.muxs.f(mux_file_mapper)).inheritors_mapper
                       CompositeMapper::Mux.new(etc_mapper: etc_mapper, lib_mapper: @lib.muxs.f(mux_file_mapper))
                     else
                       plug = PathMapper.new("/tmp/sx/null/#{SecureRandom.uuid}")
                       CompositeMapper::Mux.new(etc_mapper: plug, lib_mapper: plug)
                     end

        self.class.index[name] = { mapper: mapper, mux_mapper: mux_mapper, state_mapper: state_mapper, model_name: model_name }
      end
    end
  end
end
