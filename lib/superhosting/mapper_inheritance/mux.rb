module Superhosting
  module MapperInheritance
    class Mux
      include Base

      def initialize(mapper)
        super()
        @mapper = mapper
        @muxs_mapper = @mapper.parent
        self.collect_inheritors
      end

      def set_inheritors(mapper=@mapper)
        raise NetStatus::Exception, { error: :input_error, code: :mux_does_not_exists, data: { name: mapper.name } } unless mapper.dir?
        raise NetStatus::Exception, { error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: mapper.name } } if mapper.abstract?
        super(mapper)
      end

      def collect_inheritors(m=@mapper, depth=0)
        depth += 1

        m.inherit.lines.each do |name|
          inherit_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :mux_does_not_exists, data: { name: name } } unless inherit_mapper.dir?

          collect_inheritors(inherit_mapper, depth)
        end

        collect_inheritor(m, depth) unless m == @mapper
      end

      def collect_inheritor(mapper, depth)
        (self.inheritors[depth] ||= []) << mapper
      end

      def set_inheritance(mapper)
        self.inheritors.sort.each do |k, inheritors|
          inheritors.each do |inheritor|
            if inheritor.dir?
              inheritor.changes_overlay = mapper
              mapper << inheritor
            end
          end
        end
        mapper
      end
    end
  end
end
