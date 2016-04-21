module Superhosting
  module Controller
    class Model < Base
      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def list(abstract: false)
        { data: self._list(abstract: abstract) }
      end

      def _list(abstract: false)
        models = []
        @config.models.grep_dirs.each do |model_mapper|
          next if !abstract and model_mapper.abstract?
          models << { 'name' => model_mapper.name, 'abstract' => model_mapper.abstract? }
        end
        models
      end

      def tree(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          { data: MapperInheritance::Model.new(@config.models.f(name)).collect_inheritors_tree[name] }
        else
          resp
        end
      end

      def inspect(name:, inheritance: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = MapperInheritance::Model.new(@config.models.f(name)).set_inheritors(@config.models.f(name))
          if inheritance
            data = separate_inheritance(mapper) do |mapper, inheritors|
              (inheritors).inject([]) do |inheritance, m|
                inheritance << { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m), 'options' => get_mapper_options(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: { 'name' => mapper.name, 'options' => get_mapper_options(mapper, erb: true) } }
          end
        else
          resp
        end
      end

      def options(name:, inheritance: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = MapperInheritance::Model.new(@config.models.f(name)).set_inheritors(@config.models.f(name))
          if inheritance
            data = separate_inheritance(mapper) do |mapper, inheritors|
              (inheritors).inject([]) do |inheritance, m|
                type, name = get_mapper_type(m), get_mapper_name(m)
                inheritance << { "#{ "#{type}: " if type == 'mux' }#{name}" => get_mapper_options_pathes(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: get_mapper_options_pathes(mapper, erb: true) }
          end
        else
          resp
        end
      end

      def inheritance(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          model_mapper = @config.models.f(name)
          inheritance = MapperInheritance::Model.new(model_mapper).inheritors
          inheritance.delete(model_mapper)
          { data: inheritance.map { |m| { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m) } } }
        else
          resp
        end
      end

      def reconfigure(name:)
        if (resp = self.useable_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.reconfigure(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)
        if (resp = self.useable_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.update(name: container_name)).net_status_ok?
          end
        end
        resp
      end
    end
  end
end