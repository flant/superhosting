module Superhosting
  module Helper
    module Mapper
      def separate_inheritance(mapper)
        inheritance = mapper.inheritance
        mapper.inheritance = []
        inheritance.each {|i| i.erb_options = mapper.erb_options }
        yield mapper, inheritance
      ensure
        mapper.inheritance = inheritance
      end

      def get_mapper_type(mapper)
        case mapper.name
          when 'containers' then 'container'
          when 'web', 'sites' then 'site'
          when 'models' then 'model'
          when 'muxs' then 'mux'
          else get_mapper_type(mapper.parent)
        end
      end

      def get_mapper_name(mapper)
        case mapper.parent.name
          when 'containers', 'models', 'muxs' then mapper.name
          else get_mapper_name(mapper.parent)
        end
      end
    end
  end
end
