module Superhosting
  module Patch
    module PathMapper
      module FileNode
        module Mixin
          extend ::Superhosting::Helper::Erb

          class << self; attr_accessor :context_options end

          def value
            content = File.read(@path).strip
            if @name.end_with? '.erb'
              self.erb(self, self.context_options, erb: content)
            else
              content
            end
          end
        end
      end
    end
  end
end

PathMapper::FileNode.send(:prepend, Superhosting::Patch::PathMapper::FileNode::Mixin)