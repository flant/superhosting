module Superhosting
  module Patch
    module PathMapper
      module Node
        module Mixin
          def self.prepended(base)
            base.class_eval do
              methods = base.instance_methods(false)
              methods.each do |name|
                with = :"#{name}_with_reload"
                without = :"#{name}_without_reload"
                @__last_methods_added = [name, with, without]

                define_method with do |*args, &block|
                  obj = ::PathMapper.new(@path)
                  if obj.nil?
                    method = (name == :method_missing) ? args.pop : name
                    obj.send(method, *args, &block)
                  else
                    self.send(without, *args, &block)
                  end
                end unless method_defined?(with)

                alias_method without, name
                alias_method name, with
              end
            end
          end
        end
      end
    end
  end
end

PathMapper::DirNode.send(:prepend, Superhosting::Patch::PathMapper::Node::Mixin)
PathMapper::FileNode.send(:prepend, Superhosting::Patch::PathMapper::Node::Mixin)