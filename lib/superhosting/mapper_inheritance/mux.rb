module Superhosting
  module MapperInheritance
    class Mux
      include Base

      def initialize(mapper)
        super(mapper)
        @muxs_mapper = @mapper.parent
      end

      def get
        raise NetStatus::Exception, { error: :input_error, code: :mux_does_not_exists, data: { name: @mapper.name } } unless @mapper.dir?
        raise NetStatus::Exception, { error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: @mapper.name } } if @mapper.abstract?
        super
      end

      def set_inheritors(m=@mapper, depth=0)
        depth += 1

        m.inherit.lines.each do |name|
          inherit_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, { error: :logical_error, code: :mux_does_not_exists, data: { name: name } } unless inherit_mapper.dir?

          set_inheritors(inherit_mapper, depth)
        end

        set_inheritor(m, depth) unless m == @mapper
      end

      def set_inheritor(mapper, depth)
        if (type_dir_mapper = mapper).dir?
          (@inheritors[depth] ||= []) << type_dir_mapper
        end
      end
    end
  end
end
