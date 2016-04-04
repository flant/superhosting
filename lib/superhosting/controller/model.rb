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
        def show_tree(node)
          node.each do |k, hash|
            self.info(k.name)
            self.indent_step
            %w(mux model).each do |type|
              if !hash[type].nil? and !hash[type].empty?
                self.info(type)
                self.indent_step
                (hash[type] || []).each do |v|
                  if v.is_a? Hash
                    self.show_tree(v)
                  else
                    self.info(v)
                  end
                end
                self.indent_step_back
              end
            end
            self.indent_step_back
          end
        end

        if (resp = self.existing_validation(name: name)).net_status_ok?
          # TODO
          old = self.indent
          inheritance = MapperInheritance::Model.new(@config.models.f(name))
          inheritance.collect_inheritors_tree
          self.show_tree(inheritance.inheritors_tree)
          self.indent = old

          resp = {}
        end
        resp
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

      end

      def useable_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :model_does_not_used, data: { name: name } }
      end

      def existing_validation(name:)
        self._list.include?(name) ? {} : { error: :logical_error, code: :model_does_not_exists, data: { name: name } }
      end

      def index
        @index || self.reindex
      end

      def reindex
        @index ||= {}
        @container_controller.list[:data].each do |container|
          container_mapper = @container_controller.index[container[:name]][:mapper]
          model = container_mapper.f('model', default: @config.default_model).value

          (@index[model] ||= []) << container[:name]
        end
        @index
      end
    end
  end
end