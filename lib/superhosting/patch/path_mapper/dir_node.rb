module Superhosting
  module Patch
    module PathMapper
      module DirNode
        module Mixin
          def initialize(path)
            super
            @inheritance = []
          end

          def <<(mapper)
            @inheritance << mapper
          end

          def f(m, **kwargs)
            base_obj = ::PathMapper.new(@path.join(m.to_s))
            @inheritance.each do |inherit|
              [m.to_s, "#{m.to_s}.erb"].each do |fname|
                obj = inherit.f(fname)
                return obj unless obj.empty?
              end
            end if base_obj.empty?
            (base_obj.empty? and kwargs.key? :default) ? kwargs[:default] : base_obj
          end
        end
      end
    end
  end
end

PathMapper::DirNode.send(:prepend, Superhosting::Patch::PathMapper::DirNode::Mixin)