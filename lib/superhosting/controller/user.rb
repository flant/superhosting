module Superhosting
  module Controller
    class User < Base
      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def list(container_name:)
        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          { data: _get_group_users(name: container_name) }
        else
          resp
        end
      end

      def add(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        container_web = "/web/#{container_name}"
        home_dir = ftp_dir.nil? ? container_web : File.join(container_web, ftp_dir)

        if !ftp_dir.nil? and !ftp_only
          { error: :logical_error, message: 'Option \'ftp-only\' is required if specified \'ftp-dir\'' }
        elsif File.exists? home_dir
          { error: :logical_error, message: "Incorrect ftp-dir '#{home_dir}'"}
        elsif (resp = @container_controller.existing_validation(name: container_name)).net_status_ok? and
          (resp = self.not_existing_validation(name: name, container_name: container_name)).net_status_ok?
          shell = ftp_only ? '/usr/sbin/nologin' : '/bin/bash'
          self._add(name: name, container_name: container_name, home_dir: home_dir, shell: shell)
          generate ? { data: self.passwd(name: user_name, generate: generate).net_status_ok![:data] } : {}
        else
          resp
        end
      end

      def passwd(name:, generate: false)
        passwords = self._create_password(generate)
        self._update_password(name: name, encrypted_password: passwords[:encrypted_password])
        generate ? { data: { password: passwords[:password], encrypted_password: passwords[:encrypted_password] } } : {}
      end

      def delete(name:, container_name:)
        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok? and
            (resp = self.existing_validation(name: name, container_name: container_name)).net_status_ok?
          container_lib_mapper = @lib.containers.f(container_name)
          passwd_path = container_lib_mapper.configs.f('etc-passwd')._path
          user_name = "#{container_name}_#{name}"
          self._del(name: user_name)
          pretty_remove(passwd_path, /#{user_name}.*/)

          {}
        else
          self.debug("User '#{name}' has already been deleted")
        end
      end

      def change(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        if (resp = self.delete(name: name, container_name: container_name)).net_status_ok?
          self.add(name: name, container_name: container_name, ftp_dir: ftp_dir, ftp_only: ftp_only, generate: generate)
        else
          resp
        end
      end

      def _add(name:, container_name:, shell: '/usr/sbin/nologin', home_dir: "/web/#{container_name}")
        self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: shell, home_dir: home_dir)
      end

      def _add_custom(name:, group:, shell: '/usr/sbin/nologin', home_dir: "/web/#{group}")
        container_lib_mapper = @lib.containers.f(group)
        passwd_path = container_lib_mapper.configs.f('etc-passwd')._path
        self.command("useradd #{name} -g #{group} -d #{home_dir} -s #{shell}")
        user = self._get(name: name)
        pretty_write(passwd_path, "#{name}:x:#{user.uid}:#{user.gid}::#{home_dir}:#{shell}")
      end

      def _group_get(name:)
        begin
          Etc.getgrnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _group_add(name:)
        self.command("groupadd #{name}")
      end

      def _del(name:)
        self.command("userdel #{name}")
      end

      def _get(name:)
        begin
          Etc.getpwnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _get_group_users(name:)
        if group = self._group_get(name: name)
          gid = group.gid

          users = []
          Etc.passwd do |user|
            users << user.name if user.gid == gid
          end
          users
        else
          []
        end
      end

      def _del_group_users(name:)
        self._get_group_users(name: name).each {|user| self._del(name: user) }
      end

      def _create_password(generate: false)
        password = generate ? SecureRandom.hex : ask('Password:  ') { |q| q.echo = "*" }
        encrypted_password = OpenSSL::Digest::MD5.hexdigest(password)
        { password: password, encrypted_password: encrypted_password }
      end

      def _update_password(name:, encrypted_password:)
        self.command("usermod -p #{encrypted_password} #{name}")
      end

      def existing_validation(name:, container_name:)
        container_lib_mapper = @lib.containers.f(container_name)
        passwd_path = container_lib_mapper.configs.f('etc-passwd')._path
        user_name = "#{container_name}_#{name}"

        check_in_file(passwd_path, name) ?  {} : { error: :logical_error, message: "User '#{user_name}' doesn't exists" }
      end

      def not_existing_validation(name:, container_name:)
        self.existing_validation(name: name, container_name: container_name).net_status_ok? ? { error: :logical_error, message: "User '#{name}_#{container_name}' already exists" } : {}
      end
    end
  end
end