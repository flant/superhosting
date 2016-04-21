module Superhosting
  module Controller
    class User
      def _group_get(name:)
        Etc.getgrnam(name)
      rescue ArgumentError => e
        nil
      end

      def _group_get_users(name:)
        if (group = _group_get(name: name))
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
        _group_get_users(name: name).map(&:name)
      end

      def _group_get_system_users(name:)
        if (base_user = _get(name: name))
          _group_get_users(name: name).map { |u| u.name.slice(/(?<=#{name}_).*/) if u.uid != base_user.uid }.compact
        else
          []
        end
      end

      def _group_add(name:)
        debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          with_dry_run do |dry_run|
            resp = {}
            if _group_get(name: name).nil?
              resp = command!("groupadd #{name}", debug: false) unless dry_run
              blk.call(code: :added)
            else
              blk.call(code: :ok)
            end
            resp
          end
        end
      end

      def _group_del(name:)
        debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          with_dry_run do |dry_run|
            resp = {}
            if _group_get(name: name)
              resp = command!("groupdel #{name}", debug: false) unless dry_run
              blk.call(code: :deleted)
            else
              blk.call(code: :ok)
            end
            resp
          end
        end
      end

      def _group_del_users(name:)
        _group_get_users_names(name: name).each { |user| _del(name: user, group: name) }
      end
    end
  end
end
