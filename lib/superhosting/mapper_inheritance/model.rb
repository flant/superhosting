module Superhosting
  module MapperInheritance
    class Model
      include Base

      def initialize(mapper, model_mapper)
        super(mapper)
        @model_mapper = model_mapper
        @models_mapper = @model_mapper.parent
        @muxs_mapper = @models_mapper.parent.muxs

        @type = case type = mapper.parent.name
          when 'containers' then 'container'
          when 'sites' then 'site'
          else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
        end
      end

      def get
        raise NetStatus::Exception, { error: :input_error, code: :model_does_not_exists, data: { name: @model_mapper.name } } unless @model_mapper.dir?
        raise NetStatus::Exception, { error: :logical_error, code: :base_model_should_not_be_abstract, data: { name: @model_mapper.name } } if @model_mapper.abstract?
        super
      end

      def set_inheritors(m=@model_mapper, depth=0, mux=false)
        depth += 1

        # mux
        m.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: name } } if mux_mapper.abstract?
          raise NetStatus::Exception, { error: :logical_error, code: :mux_does_not_exists, data: { name: name } } unless mux_mapper.dir?
          set_inheritor(mux_mapper, depth)
          depth = set_inheritors(mux_mapper, depth, true)
        end

        m.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :model_does_not_exists, data: { name: name } } unless inherit_mapper.dir?

          # mixed
          set_inheritors(inherit_mapper, depth, mux)
        end

        # model
        set_inheritor(m, depth)

        depth
      end

      def set_inheritor(mapper, depth)
        if (type_dir_mapper = mapper.f(@type)).dir?
          (@inheritors[depth] ||= []) << type_dir_mapper
        end
      end
    end
  end
end
