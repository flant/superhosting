module Superhosting
  module Patch
    module PathMapperNode
      module Mixin
        def self.included(base)
          base.class_eval do
            methods = base.instance_methods(false)
            methods.each do |name|
              with = :"#{name}_with_reload"
              without = :"#{name}_without_reload"
              @__last_methods_added = [name, with, without]

              define_method with do |*args, &block|
                obj = PathMapper.new(@path)
                method = if obj.nil?
                  (name == :method_missing) ? args.pop : name
                else
                  without
                end
                obj.send(method, *args, &block)
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

PathMapper::DirNode.send(:include, Superhosting::Patch::PathMapperNode::Mixin)
PathMapper::FileNode.send(:include, Superhosting::Patch::PathMapperNode::Mixin)