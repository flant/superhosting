module Superhosting
  module MapperInheritance
    module Base
      attr_accessor :inheritors, :inheritors_tree

      def initialize
        self.inheritors = {}
        self.inheritors_tree = {}
      end

      def set_inheritors(mapper)
        self.set_inheritance(mapper)
      end
    end
  end
end
