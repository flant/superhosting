module Superhosting
  module Controller
    class Admin < Base
      def initialize(**kwargs)
        super(**kwargs)
        @admins_mapper = @config.admins
      end

      def list
        admins = {}
        @admins_mapper.grep_dirs.map do |dir_name|
          admin_name = dir_name.name

          container_admin_controller = self.get_controller(Admin::Container, name: admin_name)
          if (resp = container_admin_controller.list).net_status_ok?
            admins[admin_name] = resp[:data]
          else
            return resp
          end
        end

        { data: admins }
      end

      def add(name:, generate: false)
        if (resp = self.not_existing_validation(name: name)).net_status_ok?
          admin_dir = @admins_mapper.f(name)
          admin_dir.create!
          admin_dir.passwd.put!(name)
          self.command!("chmod 640 #{admin_dir.path}")
          self.passwd(name: name, generate: generate)
        end
        resp
      end

      def delete(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          admin_container_controller = self.get_controller(Admin::Container, name: name)
          if (resp = admin_container_controller._delete_all_users).net_status_ok?
            admin_dir = @admins_mapper.f(name)
            admin_dir.delete!
          end
        end
        resp
      end

      def passwd(name:, generate: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          user_controller = self.get_controller(User)
          admin_dir = @admins_mapper.f(name)
          passwords = user_controller._create_password(generate: generate)
          admin_dir.passwd.put!("#{name}:#{passwords[:encrypted_password]}")

          users = self.index[name]
          users.each do |user_name|
            user_controller._update_password(name: user_name, encrypted_password: passwords[:encrypted_password])
          end

          { data: passwords }
        else
          resp
        end
      end

      def container(name:)
        self.get_controller(Container, name: name)
      end

      def existing_validation(name:)
        (@admins_mapper.f(name)).nil? ? { error: :logical_error, code: :admin_does_not_exists, data: { name: name } } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :admin_exists, data: { name: name } } : {}
      end

      def index
        index = {}
        @admins_mapper.grep_dirs.each do |dir_name|
          admin_name = dir_name.name
          admin_container_controller = self.get_controller(Admin::Container, name: admin_name)
          index[admin_name] = admin_container_controller._users_list.net_status_ok![:data] || []
        end
        index
      end
    end
  end
end