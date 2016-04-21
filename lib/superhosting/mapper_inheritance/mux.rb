module Superhosting
  module MapperInheritance
    class Mux
      include Base

      def initialize(mapper)
        super()
        @mapper = mapper
        @muxs_mapper = @mapper.parent
        collect_inheritors
      end

      def inheritors_mapper(mapper = @mapper)
        inheritance(mapper)
      end

      def collect_inheritors(m = @mapper)
        m.inherit.lines.each do |name|
          inherit_mapper = @muxs_mapper.f(name)
          collect_inheritors(inherit_mapper)
        end

        collect_inheritor(m) unless m == @mapper
      end
    end
  end
end
