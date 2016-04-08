module Superhosting
  module MapperInheritance
    class Model
      include Base

      def initialize(model_mapper)
        super()
        @model_mapper = model_mapper
        @models_mapper = @model_mapper.parent
        @muxs_mapper = @models_mapper.parent.muxs
        self.collect_inheritors
      end

      def set_inheritors(mapper)
        raise NetStatus::Exception, { error: :input_error, code: :model_does_not_exists, data: { name: @model_mapper.name } } unless @model_mapper.dir?
        raise NetStatus::Exception, { error: :logical_error, code: :base_model_should_not_be_abstract, data: { name: @model_mapper.name } } if @model_mapper.abstract?

        @type = case type = mapper.parent.name
          when 'containers' then 'container'
          when 'sites' then 'site'
          else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
        end

        super(mapper)
      end

      def collect_inheritors(m=@model_mapper, depth=0, mux=false)
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

      def collect_inheritors_tree(m=@model_mapper, node=self.inheritors_tree, mux=false)
        type = mux ? 'mux' : 'model'
        node[m] ||= {}
        node[m][type] ||= []

        # mux
        m.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: name } } if mux_mapper.abstract?
          raise NetStatus::Exception, { error: :logical_error, code: :mux_does_not_exists, data: { name: name } } unless mux_mapper.dir?
          (node[m]['mux'] ||= []) << collect_inheritors_tree(mux_mapper, {}, true)
        end

        m.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :model_does_not_exists, data: { name: name } } unless inherit_mapper.dir?

          # mixed
          node[m][mux ? 'mux' : 'model'] << collect_inheritors_tree(inherit_mapper, {}, mux)
        end

        node
      end

      def collect_inheritor(mapper, depth, mux)
        self.inheritors[depth] ||= {}
        (self.inheritors[depth][mux ? 'mux' : 'model'] ||= []) << mapper
      end

      def set_inheritance(mapper)
        self.inheritors.sort.each do |k, inherits|
          %w(mux model).each do |t|
            (inherits[t] || []).each do |inheritor|
              if (type_dir_mapper = inheritor.f(@type)).dir?
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
