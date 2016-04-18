module Superhosting
  module Controller
    class Model < Base
      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def list
        { data: self._list }
      end

      def _list
        models = []
        @config.models.grep_dirs.each do |model_mapper|
          models << model_mapper.name unless model_mapper.abstract?
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
                inheritance << { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m), 'options' => m.to_hash }
              end
            end
            { data: data }
          else
            { data: { 'name' => mapper.name, 'options' => mapper.to_hash } }
          end
        else
          resp
        end
      end

      def inheritance(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = MapperInheritance::Model.new(@config.models.f(name)).set_inheritors(@config.models.f(name))
          { data: mapper.inheritance.map{|m| { 'type' => get_mapper_type(m.parent), 'name' => get_mapper_name(m) } } }
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