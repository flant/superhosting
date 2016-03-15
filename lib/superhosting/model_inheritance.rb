module Superhosting
  class ModelInheritance
    def initialize(mapper, model_mapper)
      @mapper = mapper.create!
      @model_mapper = model_mapper
      @models_mapper = model_mapper.parent
      @inheritors = {}

      @type = case type = mapper.parent.name
        when 'containers' then 'container'
        when 'sites' then 'site'
        else raise NetStatus::Exception, { error: :logical_error, code: :mapper_type_not_supported, data: { name: type } }
      end
    end

    def get
      def set_inheritors(m, depth=0)
        depth += 1
        m.inherit.lines do |line|
          model_name = line.strip
          inherit_mapper = @models_mapper.f(model_name)
          raise NetStatus::Exception, { error: :logical_error, code: :model_does_not_exists, data: { name: model_name } } unless inherit_mapper.dir?

          set_inheritors(inherit_mapper, depth)

          if (type_dir_mapper = inherit_mapper.f(@type)).dir?
            (@inheritors[depth] ||= []) << type_dir_mapper
          end
        end
      end

      def set_inheritance
        @inheritors.sort.each do |k, inheritors|
          inheritors.each {|inheritor| @mapper << inheritor }
        end
      end

      raise NetStatus::Exception, { error: :input_error, code: :model_should_not_be_abstract, data: { name: @model_mapper.name } } if @model_mapper.abstract?
      set_inheritors(@model_mapper)
      set_inheritance
      @mapper
    end
  end
end
