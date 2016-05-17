module Superhosting
  module MapperInheritance
    module Base
      include Helper::Mapper

      def inheritors_cache
        @inheritors_cache ||= {}
      end

      def get_or_collect(mapper, inheritors = [], *args)
        key = mapper.path
        inheritors_cache[key] = collect_inheritors(mapper, *args) if inheritors_cache[key].nil?
        inheritors_cache[key] + inheritors
      end

      def collect_inheritors(*_args)
      end

      def inheritors_tree(mapper, mux: false)
        tree = {}
        type = mux ? 'mux' : 'model'
        m_key = mapper.name
        tree[m_key] ||= {}
        tree[m_key][type] ||= []

        # mux
        mapper.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: name } if mux_mapper.abstract?
          raise NetStatus::Exception, error: :logical_error, code: :mux_does_not_exists, data: { name: name } unless mux_mapper.dir?
          (tree[m_key]['mux'] ||= []) << inheritors_tree(mux_mapper, mux: true)
        end

        mapper.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)
          raise NetStatus::Exception, error: :logical_error, code: :model_does_not_exists, data: { name: name } unless inherit_mapper.dir?

          # mixed
          tree[m_key][mux ? 'mux' : 'model'] << inheritors_tree(inherit_mapper, mux: mux)
        end

        tree
      end

      def inheritance(inheritors, mapper, type: nil)
        inheritors.each do |inheritor|
          type_dir_mapper = type.nil? ? inheritor : inheritor.f(type)
          type_dir_mapper.changes_overlay = mapper
          mapper << type_dir_mapper
        end
        mapper
      end
    end
  end
end
