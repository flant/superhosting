module Superhosting
  module MapperInheritance
    module Model
      extend Base

      class << self
        def set_inheritance(model_mapper, mapper = model_mapper)
          @models_mapper ||= model_mapper.parent
          @muxs_mapper ||= @models_mapper.parent.muxs
          inheritors = get_or_collect(model_mapper)

          type = case type_ = mapper_type(mapper)
            when 'container', 'site'
              raise NetStatus::Exception, error: :input_error, code: :model_does_not_exists, data: { name: mapper.name } unless mapper.dir?
              raise NetStatus::Exception, error: :logical_error, code: :base_model_should_not_be_abstract, data: { name: mapper.name } if mapper.abstract?
              type_
            when 'model'
              nil
            else
              raise NetStatus::Exception, error: :logical_error, code: :mapper_type_not_supported, data: { name: type_ }
          end

          inheritance(inheritors, mapper, type: type)
        end

        def collect_inheritors(mapper, mux = false)
          inheritors = []
          mapper.inherit.lines.each do |name|
            inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)

            # mixed
            inheritors = get_or_collect(inherit_mapper, inheritors, mux)
          end

          # mux
          mapper.container.mux.lines.each do |name|
            mux_mapper = @muxs_mapper.f(name)
            inheritors = get_or_collect(mux_mapper, inheritors, true)
          end

          # model
          inheritors.unshift(mapper)
          inheritors
        end
      end
    end
  end
end
