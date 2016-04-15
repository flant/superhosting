module Superhosting
  module Cli
    module Cmd
      class ModelTree < Base
        class << self
          def has_required_param?
            true
          end

          def show_models_tree(data, ignore_type: false)
            def show_tree(node, ignore_type)
              %w(model mux).each do |type|
                (node[type] || []).each {|v| show_node(v, type, ignore_type) }
              end
            end

            def show_node(node, type, ignore_type)
              node.each do |k, hash|
                self.info("#{"#{type}: " if !ignore_type and type == 'mux'}#{k}")
                self.indent_step
                self.show_tree(hash, ignore_type)
                self.indent_step_back
              end
            end

            old = self.indent
            show_tree(data, ignore_type)
            self.indent = old
          end


          def after_action(data, config)
            show_models_tree(data)
          end
        end
      end
    end
  end
end