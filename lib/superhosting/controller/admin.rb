module Superhosting
  module Controller
    class Admin < Base
      def list
        admins = []
        @admins_mapper.grep_dirs.map do |dir_name|
          admin_name = dir_name.name
          container_admin_controller = controller(Admin::Container, name: admin_name)

          unless (resp = container_admin_controller.list).net_status_ok?
            return resp
          end
          admins << { admin_name => resp[:data] }
        end

        { data: admins }
      end

      def add(name:, generate: false)
        if (resp = not_existing_validation(name: name)).net_status_ok?
          admin_dir = @admins_mapper.f(name)
          admin_dir.create!
          admin_dir.passwd.put!(name)
          reindex_admin(name: name)
          command!("chmod 640 #{admin_dir.path}")
          passwd(name: name, generate: generate)
        else
          resp
        end
      end

      def delete(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          admin_container_controller = controller(Admin::Container, name: name)
          if (resp = admin_container_controller._delete_all_users).net_status_ok?
            admin_dir = @admins_mapper.f(name)
            admin_dir.delete!
            reindex_admin(name: name)
          end
        end
        resp
      end

      def passwd(name:, generate: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          user_controller = controller(User)
          admin_dir = @admins_mapper.f(name)
          passwords = user_controller._create_password(generate: generate)
          admin_dir.passwd.put!("#{name}:#{passwords[:encrypted_password]}")

          users = index[name]
          users.each do |user_name|
            user_controller._update_password(name: user_name, encrypted_password: passwords[:encrypted_password])
          end

          generate ? { data: passwords[:password] } : {}
        else
          resp
        end
      end

      def container(name:)
        controller(Container, name: name)
      end
    end
  end
end
