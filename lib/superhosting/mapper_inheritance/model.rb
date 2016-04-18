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

      def set_inheritors(mapper)
        raise NetStatus::Exception, { error: :input_error, code: :model_does_not_exists, data: { name: @mapper.name } } unless @mapper.dir?
        raise NetStatus::Exception, { error: :logical_error, code: :base_model_should_not_be_abstract, data: { name: @mapper.name } } if @mapper.abstract?

        @type = case type = get_mapper_type(mapper)
          when 'container', 'site', 'model' then type
          else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
        end

        super(mapper)
      end

      def collect_inheritors(m=@mapper, depth=0, mux=false)
        depth += 1

        # mux
        m.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: name } } if mux_mapper.abstract?
          raise NetStatus::Exception, { error: :logical_error, code: :mux_does_not_exists, data: { name: name } } unless mux_mapper.dir?
          collect_inheritors(mux_mapper, depth, true)
        end

        m.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :model_does_not_exists, data: { name: name } } unless inherit_mapper.dir?

          # mixed
          collect_inheritors(inherit_mapper, depth, mux)
        end

        # model
        collect_inheritor(m, depth, mux)

        depth
      end

      def collect_inheritor(mapper, depth, mux)
        self.inheritors[depth] ||= {}
        (self.inheritors[depth][mux ? 'mux' : 'model'] ||= []) << mapper
      end

      def set_inheritance(mapper)
        self.inheritors.sort.each do |k, inherits|
          %w(mux model).each do |t|
            (inherits[t] || []).each do |inheritor|
              type_dir_mapper = if @type == 'model'
                inheritor
              else
                inheritor.f(@type)
              end

              if type_dir_mapper.dir?
                type_dir_mapper.changes_overlay = mapper
                mapper << type_dir_mapper
              end
            end
          end
        end
        mapper
      end
    end
  end
end
