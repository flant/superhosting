module Superhosting
  module Controller
    class User
      def _group_get(name:)
        begin
          Etc.getgrnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _group_get_users(name:)
        if (group = self._group_get(name: name))
          gid = group.gid

          users = []
          Etc.passwd do |user|
            users << user if user.gid == gid
          end
          users
        else
          []
        end
      end

      def _group_get_users_names(name:)
        self._group_get_users(name: name).map(&:name)
      end

      def _group_get_system_users(name:)
        if (base_user = self._get(name: name))
          self._group_get_users(name: name).map { |u| u.name.slice(/(?<=#{name}_).*/) if u.uid != base_user.uid }.compact
        else
          []
        end
      end

      def _group_add(name:)
        self.debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            if self._group_get(name: name).nil?
              resp = self.command!("groupadd #{name}", debug: false) unless dry_run
              blk.call(code: :added)
            else
              blk.call(code: :ok)
            end
            resp
          end
        end
      end

      def _group_del(name:)
        self.debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            if self._group_get(name: name)
              unless dry_run
                resp = self.command!("groupdel #{name}", debug: false)
              end
              blk.call(code: :deleted)
            else
              blk.call(code: :ok)
            end
            resp
          end
        end
      end

      def _group_del_users(name:)
        self._group_get_users_names(name: name).each { |user| self._del(name: user, group: name) }
      end
    end
  end
end
