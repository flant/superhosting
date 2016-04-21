module Superhosting
  module MapperInheritance
    class Model
      include Base

      def initialize(model_mapper)
        super()
        @mapper = model_mapper
        @models_mapper = @mapper.parent
        @muxs_mapper = @models_mapper.parent.muxs
        self.collect_inheritors
      end

      def inheritors_mapper(mapper)
        raise NetStatus::Exception, error: :input_error, code: :model_does_not_exists, data: { name: @mapper.name } unless @mapper.dir?
        raise NetStatus::Exception, error: :logical_error, code: :base_model_should_not_be_abstract, data: { name: @mapper.name } if @mapper.abstract?

        @type = case type = mapper_type(mapper)
          when 'container', 'site', 'model' then type
          else raise NetStatus::Exception, error: :logical_error, code: :mapper_type_not_supported, data: { name: type }
        end

        inheritance(mapper)
      end

      def collect_inheritors(m = @mapper, mux = false)
        m.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)

          # mixed
          collect_inheritors(inherit_mapper, mux)
        end

        # mux
        m.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          collect_inheritors(mux_mapper, true)
        end

        # model
        collect_inheritor(m)
      end
    end
  end
end
