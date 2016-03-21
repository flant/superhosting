module Superhosting
  module Controller
    class User < Base
      USER_NAME_FORMAT = /^[a-zA-Z][-a-zA-Z0-9_]{3,32}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def list(container_name:)
        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          { data: _group_get_users(name: container_name) }
        else
          resp
        end
      end

      def add(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        return { error: :logical_error, code: :option_ftp_only_is_required } if ftp_dir and !ftp_only

        web_mapper = PathMapper.new("/web/#{container_name}")
        home_dir = ftp_dir.nil? ? web_mapper.path : web_mapper.f(ftp_dir).path

        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          if !File.exists? home_dir
            resp = { error: :logical_error, code: :incorrect_ftp_dir, data: { dir: home_dir.to_s } }
          elsif (resp = self.not_existing_validation(name: name, container_name: container_name)).net_status_ok?
            shell = ftp_only ? '/usr/sbin/nologin' : '/bin/bash'
            if (resp = self._add(name: name, container_name: container_name, home_dir: home_dir, shell: shell)).net_status_ok?
              if generate
                if (resp = self.passwd(name: user_name, generate: generate)).net_status_ok?
                  resp = { data: resp[:data] }
                end
              end
              resp
            end
          end
        end
        resp
      end

      def passwd(name:, generate: false)
        passwords = self._create_password(generate: generate)
        self._update_password(name: name, encrypted_password: passwords[:encrypted_password])
        generate ? { data: { password: passwords[:password], encrypted_password: passwords[:encrypted_password] } } : {}
      end

      def delete(name:, container_name:)
        if (resp = @container_controller.existing_validation(name: container_name)).net_status_ok?
          if self.not_existing_validation(name: name, container_name: container_name).net_status_ok?
            self.debug("User '#{name}' has already been deleted")
          else
            container_lib_mapper = @lib.containers.f(container_name)
            passwd_path = container_lib_mapper.configs.f('etc-passwd').path
            user_name = "#{container_name}_#{name}"
            self._del(name: user_name)
            pretty_remove(passwd_path, /#{user_name}.*/)
          end
        end
        resp
      end

      def change(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        if (resp = self.delete(name: name, container_name: container_name)).net_status_ok?
          self.add(name: name, container_name: container_name, ftp_dir: ftp_dir, ftp_only: ftp_only, generate: generate)
        else
          resp
        end
      end

      def _get(name:)
        begin
          Etc.getpwnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _add(name:, container_name:, shell: '/usr/sbin/nologin', home_dir: "/web/#{container_name}")
        self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: shell, home_dir: home_dir)
      end

      def _add_custom(name:, group:, shell: '/usr/sbin/nologin', home_dir: "/web/#{group}")
        if (resp = self.adding_validation(name: name, container_name: group)).net_status_ok?
          container_lib_mapper = @lib.containers.f(group)
          passwd_path = container_lib_mapper.configs.f('etc-passwd').path
          self.command("useradd #{name} -g #{group} -d #{home_dir} -s #{shell}")
          user = self._get(name: name)
          pretty_override(passwd_path, "#{name}:x:#{user.uid}:#{user.gid}::#{home_dir}:#{shell}")
        else
          resp
        end
      end

      def _del(name:)
        self.command("userdel #{name}")
      end

      def _create_password(generate: false)
        password = if generate
          SecureRandom.hex
        else
          begin
            pass = ask('Enter password: ') { |q| q.echo = false }
            re_pass = ask('Repeat password: ') { |q| q.echo = false }
          end until pass == re_pass and !pass.empty?
          pass
        end
        encrypted_password = UnixCrypt::SHA512.build(password)
        { password: password, encrypted_password: encrypted_password }
      end

      def _update_password(name:, encrypted_password:)
        self.command("usermod -p '#{encrypted_password}' #{name}")
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

      def _group_del(name:)
        self.command("groupdel #{name}")
      end

      def _group_get_users(name:)
        if (group = self._group_get(name: name))
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

      def _group_del_users(name:)
        self._group_get_users(name: name).each {|user| self._del(name: user) }
        self._group_del(name: name)
      end

      def adding_validation(name:, container_name:)
        return { error: :input_error, code: :invalid_user_name, data: { name: name, regex: USER_NAME_FORMAT } } if name !~ USER_NAME_FORMAT
        self.not_existing_validation(name: name, container_name: container_name)
      end

      def existing_validation(name:, container_name:)
        user_name = "#{container_name}_#{name}"
        check_in_file('/etc/passwd', user_name) ? {} : { error: :logical_error, code: :user_does_not_exists, data: { name: user_name } }
      end

      def not_existing_validation(name:, container_name:)
        self.existing_validation(name: name, container_name: container_name).net_status_ok? ? { error: :logical_error, code: :user_exists, data: { name: "#{container_name}_#{name}" } } : {}
      end
    end
  end
end