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

      def collect_inheritors(m=@mapper)
        m.inherit.lines.each do |name|
          inherit_mapper = @muxs_mapper.f(name)
          collect_inheritors(inherit_mapper)
        end

        collect_inheritor(m) unless m == @mapper
      end
    end
  end
end
