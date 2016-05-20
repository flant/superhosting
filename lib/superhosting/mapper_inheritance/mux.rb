module Superhosting
  module MapperInheritance
    module Mux
      extend Base

      class << self
        def set_inheritance(mux_mapper, mapper = mux_mapper)
          @muxs_mapper ||= mux_mapper.parent
          inheritors = get_or_collect(mux_mapper, [], true)
          inheritance(inheritors, mapper)
        end

        def collect_inheritors(mapper, not_save = false)
          inheritors = []
          mapper.inherit.lines.each do |name|
            inherit_mapper = @muxs_mapper.f(name)
            inheritors = get_or_collect(inherit_mapper, inheritors)
          end

          inheritors.unshift(mapper) unless not_save
          inheritors
        end

        def tree(mapper)
          @muxs_mapper = mapper.parent
          @models_mapper = @muxs_mapper.parent.muxs
          inheritors_tree(mapper, mux: true)
        end
      end
    end
  end
end
