module Superhosting
  module MapperInheritance
    module Base
      def initialize(mapper)
        @mapper = mapper
        @inheritors = {}
      end

      def get
        self.set_inheritors
        self.set_inheritance
        @mapper
      end

      def set_inheritance
        @inheritors.sort.each do |k, inheritors|
          inheritors.each {|inheritor| @mapper << inheritor }
        end
      end
    end
  end
end
