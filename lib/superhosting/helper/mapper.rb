module Superhosting
  module Helper
    module Mapper
      def separate_inheritance(mapper)
        inheritance = mapper.inheritance
        mapper.inheritance = []
        inheritance.each { |i| i.erb_options = mapper.erb_options }
        yield mapper, inheritance
      ensure
        mapper.inheritance = inheritance
      end

      def mapper_type(mapper)
        case mapper.name
          when 'containers' then
            'container'
          when 'web', 'sites' then
            'site'
          when 'models' then
            'model'
          when 'muxs' then
            'mux'
          else
            mapper_type(mapper.parent)
        end
      end

      def mapper_name(mapper)
        case mapper.parent.name
          when 'containers', 'models', 'muxs' then
            mapper.name
          else
            mapper_name(mapper.parent)
        end
      end

      def get_mapper_options(mapper, erb: false)
        exclude_erb_extension = lambda do |h|
          new_hash = {}
          h.each do |k, v|
            if v.is_a? Hash
              new_hash[k] = exclude_erb_extension.call(h[k])
            else
              new_hash[k[/(.*(?=\.erb))|(.*)/]] = h.delete(k)
            end
          end
          new_hash
        end

        hash = mapper.to_hash(eval_erb: !erb, exclude_files: [/^config.rb$/, /^inherit$/, /^abstract$/], exclude_dirs: [/^config_templates$/])
        exclude_erb_extension.call(hash)
      end

      def get_mapper_options_pathes(mapper, erb: false)
        get_pathes = lambda do |h, path = []|
          options = {}
          h.each do |k, v|
            path_ = path.dup
            path_ << k
            if v.is_a? Hash
              options.merge!(get_pathes.call(h[k], path_))
            else
              options.merge!(path_.join('.') => v)
            end
          end
          options
        end

        hash = get_mapper_options(mapper, erb: erb)
        get_pathes.call(hash)
      end

      def inspect(name:, inheritance: false, erb: false)
        if inheritance
          inheritance_mapper = index[name].inheritance_mapper
          separate_inheritance(inheritance_mapper) do |base, inheritors|
            ([base] + inheritors).reverse.inject([]) do |total, m|
              total << { 'type' => mapper_type(m.parent), 'name' => mapper_name(m), 'options' => get_mapper_options(m, erb: erb) }
            end
          end
        else
          _inspect(name: name, erb: erb)
        end
      end

      def options(name:, inheritance: false, erb: false)
        inheritance_mapper = index[name].inheritance_mapper
        mapper_type = mapper_type(inheritance_mapper)
        if inheritance
          separate_inheritance(inheritance_mapper) do |base, inheritors|
            ([base] + inheritors).reverse.inject([]) do |total, m|
              type = mapper_type(m)
              name = mapper_name(m)
              name = type if type == mapper_type
              total << { "#{"#{type}: " if type == 'mux'}#{name}" => get_mapper_options_pathes(m, erb: erb) }
            end
          end
        else
          get_mapper_options_pathes(inheritance_mapper, erb: erb)
        end
      end

      def inheritance(name:)
        inheritance_mapper = index[name].inheritance_mapper
        inheritance_mapper.inheritance.reverse.map { |m| { 'type' => mapper_type(m.parent), 'name' => mapper_name(m) } }
      end
    end
  end
end
