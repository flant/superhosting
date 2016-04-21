module Superhosting
  module Controller
    class Container
      def initialize(**kwargs)
        super
        self.index
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @config.containers.grep_dirs.each { |mapper| self.reindex_container(name: mapper.name) }
        @@index ||= {}
      end

      def reindex_container(name:)
        @@index ||= {}
        etc_mapper = @config.containers.f(name)
        web_mapper = PathMapper.new('/web').f(name)
        lib_mapper = @lib.containers.f(name)
        state_mapper = lib_mapper.state

        if etc_mapper.nil?
          @@index.delete(name)
          return
        end

        model_name = etc_mapper.f('model', default: @config.default_model).value
        model_mapper = @config.models.f(model_name)
        etc_mapper = MapperInheritance::Model.new(model_mapper).set_inheritors(etc_mapper)

        mapper = CompositeMapper.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)

        etc_mapper.erb_options = { container: mapper, etc: @config, lib: @lib }
        mux_mapper = if (mux_file_mapper = etc_mapper.mux).file?
          MapperInheritance::Mux.new(@config.muxs.f(mux_file_mapper)).set_inheritors
        end

        @@index[name] = { mapper: mapper, mux_mapper: mux_mapper, state_mapper: state_mapper, model_name: model_name }
      end
    end
  end
end