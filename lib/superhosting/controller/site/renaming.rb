module Superhosting
  module Controller
    class Site
      def new_up(name:, new_name:, container_name:, is_alias:)
        mapper = self.index[name][:mapper]
        mapper.aliases_mapper.remove_line!(new_name) if defined? is_alias and is_alias
        self.reindex_site(name: name, container_name: container_name)
        self._reconfigure(name: new_name, container_name: container_name)
      end

      def undo_new_up(new_name:)
        self.delete(name: new_name)
      end

      def copy(name:, new_name:)
        mapper = self.index[name][:mapper]
        new_mapper = self.index[new_name][:mapper]

        mapper.etc.rename!(new_mapper.etc.path)
        mapper.lib.rename!(new_mapper.lib.path)
        mapper.aliases_mapper.rename!(new_mapper.aliases_mapper.path)

        {}
      end

      def undo_copy(name:, new_name:)
        new_mapper = self.index[new_name][:mapper]
        mapper = self.index[name][:mapper]

        unless mapper.nil?
          new_mapper.etc.safe_rename!(mapper.etc.path)
          new_mapper.lib.safe_rename!(mapper.lib.path)
          new_mapper.aliases_mapper.safe_rename!(mapper.aliases_mapper.path)
        end

        {}
      end

      def new_reconfigure(new_name:)
        self.reconfigure(name: new_name)
      end

      def undo_new_reconfigure(new_name:)
        self.unconfigure_with_unapply(name: new_name)
      end

      def keep_name_as_alias(name:, new_name:, keep_name_as_alias:)
        new_mapper = self.index[new_name][:mapper]
        new_container_mapper = self.index[new_name][:container_mapper]

        new_mapper.aliases_mapper.append_line!(name) if keep_name_as_alias
        self.reindex_container_sites(container_name: new_container_mapper.name)

        {}
      end
    end
  end
end