module Superhosting
  module Cli
    module Cmd
      class ModelTree < Base
        class << self
          def has_required_param?
            true
          end

          def after_action(data, config)
            def show_tree(node, type='model')
              node.each do |k, hash|
                self.info("#{"#{type}: " if type == 'mux'}#{k.name}")
                self.indent_step
                %w(mux model).each do |type|
                  (hash[type] || []).each {|v| show_tree(v, type) } if !hash[type].nil? and !hash[type].empty?
                end
                self.indent_step_back
              end
            end

            old = self.indent
            show_tree(data)
            self.indent = old
          end
        end
      end
    end
  end
end