module Superhosting
  module MapperInheritance
    module Base
      include Helper::Mapper

      attr_accessor :inheritors, :inheritors_tree

      def initialize
        self.inheritors = []
        self.inheritors_tree = {}
      end

      def collect_inheritors_tree(m = @mapper, node = inheritors_tree, mux: false)
        type = mux ? 'mux' : 'model'
        m_key = m.name
        node[m_key] ||= {}
        node[m_key][type] ||= []

        # mux
        m.container.mux.lines.each do |name|
          mux_mapper = @muxs_mapper.f(name)
          raise NetStatus::Exception, error: :logical_error, code: :base_mux_should_not_be_abstract, data: { name: name } if mux_mapper.abstract?
          raise NetStatus::Exception, error: :logical_error, code: :mux_does_not_exists, data: { name: name } unless mux_mapper.dir?
          (node[m_key]['mux'] ||= []) << collect_inheritors_tree(mux_mapper, {}, mux: true)
        end

        m.inherit.lines.each do |name|
          inherit_mapper = (mux ? @muxs_mapper : @models_mapper).f(name)
          raise NetStatus::Exception, error: :logical_error, code: :model_does_not_exists, data: { name: name } unless inherit_mapper.dir?

          # mixed
          node[m_key][mux ? 'mux' : 'model'] << collect_inheritors_tree(inherit_mapper, {}, mux: mux)
        end

        node
      end

      def collect_inheritor(mapper)
        inheritors.unshift(mapper)
      end

      def inheritance(mapper)
        inheritors.each do |inheritor|
          type_dir_mapper = @type.nil? ? inheritor : inheritor.f(@type)
          type_dir_mapper.changes_overlay = mapper
          mapper << type_dir_mapper
        end
        mapper
      end
    end
  end
end
