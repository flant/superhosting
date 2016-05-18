module Superhosting
  module Controller
    class Mysql < Base
      class << self; attr_accessor :client end

      def initialize(**kwargs)
        super
      end

      def client
        self.class.client ||= Mysql2::Client.new(host: @config.mysql.host.value,
                                                 username: @config.mysql.user.value,
                                                 password: @config.mysql.password.value)
      end

      def query(sql)
        if __debug
          debug_operation(desc: { code: :mysql_query, data: { query: sql } }) do |&blk|
            client.query(sql).tap do
              blk.call(code: :ok)
            end
          end
        else
          client.query(sql)
        end
      end

      def db
        controller(Db)
      end

      def user
        controller(User)
      end

      def alternative_name(name:)
        def container_candidate(parts, candidates)
          parts = parts.dup
          candidates = candidates.dup

          candidate = [parts.shift]
          parts.each do |part|
            candidates.select! { |c| c.start_with? candidate.join('_') }
            break if candidates.one? { |c| c == candidate.join('_') } or candidates.empty?
            candidate << part
          end
          candidates.include?(candidate.join('_')) ? candidate : nil
        end

        container_controller = controller(Container)
        container_candidates = container_controller.index.keys
        parts = name.split('_')
        candidate = container_candidate(parts, container_candidates)

        unless candidate.nil?
          slice_index = candidate.count
          container_name = candidate.join('_')
          object_name = parts.slice(slice_index..-1).join('_')
          return [container_name, object_name] unless object_name.nil?
        end

        raise NetStatus::Exception, { code: :container_name_is_not_specified }
      end

      def grant(user_name:, database_name:)
        user_controller = controller(User)
        database_controller = controller(Db)
        if (resp = user_controller.existing_validation(name: user_name)).net_status_ok? &&
           (resp = database_controller.existing_validation(name: database_name)).net_status_ok?
          _grant(user_name: user_name, database_name: database_name)
        end
        resp
      end

      def _grant(user_name:, database_name:)
        user_controller = controller(User)
        container_name = user_name.split('_').first

        debug_operation(desc: { code: :mysql_grant, data: { database: database_name, name:  user_name } }) do |&blk|
          with_dry_run do |dry_run|
            query("GRANT ALL PRIVILEGES ON #{database_name}.* TO '#{user_name}'@'%' WITH GRANT OPTION ") unless dry_run
            blk.call(code: :added)
          end
        end

        user_controller.reindex_container(container_name: container_name)
      end

      def revoke(user_name:, database_name:)
        user_controller = controller(User)
        database_controller = controller(Db)
        if (resp = user_controller.existing_validation(name: user_name)).net_status_ok? &&
           (resp = database_controller.existing_validation(name: database_name)).net_status_ok?
          _revoke(user_name: user_name, database_name: database_name)
        end
        resp
      end

      def _revoke(user_name:, database_name:)
        user_controller = controller(User)
        container_name = user_name.split('_').first

        debug_operation(desc: { code: :mysql_grant, data: { database: database_name, name:  user_name } }) do |&blk|
          with_dry_run do |dry_run|
            query("REVOKE ALL PRIVILEGES ON #{database_name}.* FROM '#{user_name}'@'%'") unless dry_run
            blk.call(code: :revoked)
          end
        end

        user_controller.reindex_container(container_name: container_name)
      end

      def _move(container_name:, new_container_name:)
        user_controller = controller(User)
        db_controller = controller(Db)

        users = user_controller.container_users(container_name: container_name).keys
        db_controller.container_dbs(container_name: container_name).each do |db_name, db_users|
          users -= db_users
          db_controller._move(name: db_name, new_container_name: new_container_name)
        end

        users.each do |full_user_name|
          _container_name, user_name = alternative_name(name: full_user_name)
          new_user_name = "#{new_container_name}_#{user_name}"
          user_controller._rename(name: full_user_name, new_name: new_user_name)
        end
      end

      def _drop(container_name:)
        mysql_db_controller = controller(Mysql::Db)
        mysql_user_controller = controller(Mysql::User)
        mysql_db_controller.container_dbs(container_name: container_name).each { |db_name, _grants| mysql_db_controller._delete(name: db_name) }
        mysql_user_controller.container_users(container_name: container_name).each { |user_name, _grants| mysql_user_controller._delete(name: user_name) }
      end
    end
  end
end
