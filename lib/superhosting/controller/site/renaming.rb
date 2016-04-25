module Superhosting
  module Controller
    class Site
      def new_up(mapper:, new_name:, container_name:, new_container_name:, is_alias:)
        name = mapper.name
        mapper.aliases_mapper.remove_line!(new_name) if is_alias
        reindex_site(name: name, container_name: container_name)
        _reconfigure(name: new_name, container_name: new_container_name)
      end

      def undo_new_up(new_name:)
        delete(name: new_name)
      end

      def copy(mapper:, new_name:)
        new_mapper = index[new_name][:mapper]

        mapper.etc.rename!(new_mapper.etc.path)
        mapper.lib.rename!(new_mapper.lib.path)
        mapper.aliases_mapper.parent.rename!(new_mapper.aliases_mapper.parent.path)

        {}
      end

      def undo_copy(mapper:, new_name:)
        new_mapper = index[new_name][:mapper]

        unless mapper.nil?
          new_mapper.etc.safe_rename!(mapper.etc.path)
          new_mapper.lib.safe_rename!(mapper.lib.path)
          new_mapper.aliases_mapper.safe_rename!(mapper.aliases_mapper.path)
        end

        {}
      end

      def new_reconfigure(new_name:)
        reconfigure(name: new_name)
      end

      def undo_new_reconfigure(new_name:)
        unconfigure_with_unapply(name: new_name)
      end

      def keep_name_as_alias(name:, new_name:, keep_name_as_alias:)
        new_mapper = index[new_name][:mapper]
        new_container_mapper = index[new_name][:container_mapper]

        new_mapper.aliases_mapper.append_line!(name) if keep_name_as_alias
        reindex_container_sites(container_name: new_container_mapper.name)

        {}
      end
    end
  end
end
