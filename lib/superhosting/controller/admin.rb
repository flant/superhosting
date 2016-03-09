module Superhosting
  module Controller
    class Admin < Base
      attr_reader :admin_index

      def admin_index
        def generate
          @admin_index = {}
          @admins_mapper.grep_dirs.each do |dir_name|
            admin_name = dir_name.name
            @admin_container_controller = self.get_controller(Admin::Container, name: admin_name)
            @admin_index[admin_name] = @admin_container_controller._users_list.net_status_ok![:data]
          end
          @admin_index
        end

        @admin_index ||= self.generate
      end

      def initialize(kwargs)
        super(**kwargs)
        @admins_mapper = @config.admins
      end

      def list
        admins = {}
        @admins_mapper.grep_dirs.map do |dir_name|
          admin_name = dir_name.name

          @container_admin_controller = self.get_controller(Admin::Container, name: admin_name)
          if (resp = @container_admin_controller.list).net_status_ok?
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
          file_write(admin_dir.passwd._path)
          self.command("chmod 640 #{admin_dir.path}")

          self.passwd(name: name, generate: generate)
        else
          resp
        end
      end

      def delete(name:)
        if self.existing_validation(name: name).net_status_ok?
          admin_dir = @admins_mapper.f(name)
          admin_dir.delete! unless admin_dir.nil?
          {}
        else
          self.debug("Admin '#{name}' has already been deleted")
        end
      end

      def passwd(name:, generate: false)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          user_controller = self.get_controller(User)
          admin_dir = @admins_mapper.f(name)
          passwords = user_controller._create_password(generate: generate)
          admin_dir.passwd.put!("#{name}:#{passwords[:encrypted_password]}")

          admin_containers = self.admin_index[name]
          admin_containers.each do |user|
            user_controller._update_password(name: user, encrypted_password: passwords[:encrypted_password])
          end unless admin_containers.nil?

          { data: passwords }
        else
          resp
        end
      end

      def container(name:)
        self.get_controller(Container, name: name)
      end

      def existing_validation(name:)
        (@config.admins.f(name)).nil? ? { error: :logical_error, message: "Admin '#{name}' doesn't exists" } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, message: "Admin '#{name}' already exists" } : {}
      end
    end
  end
end