module Superhosting
  module Controller
    class User < Base
      USER_NAME_FORMAT = /^[a-zA-Z][-a-zA-Z0-9_]{,31}$/

      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def list(container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          { data: self._list(container_name: container_name) }
        else
          resp
        end
      end

      def _list(container_name:)
        self._group_get_users_names(name: container_name)
      end

      def add(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        return { error: :logical_error, code: :option_ftp_only_is_required } if ftp_dir and !ftp_only

        web_mapper = PathMapper.new("/web/#{container_name}")
        home_dir = ftp_dir.nil? ? web_mapper.path : web_mapper.f(ftp_dir).path

        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          if !File.exists? home_dir
            resp = { error: :logical_error, code: :incorrect_ftp_dir, data: { dir: home_dir.to_s } }
          elsif (resp = self.not_existing_validation(name: name, container_name: container_name)).net_status_ok?
            shell = ftp_only ? '/usr/sbin/nologin' : '/bin/bash'
            if (resp = self._add(name: name, container_name: container_name, home_dir: home_dir, shell: shell)).net_status_ok?
              if generate
                resp = self.passwd(name: name, container_name: container_name, generate: generate)
              end
            end
          end
        end
        resp
      end

      def passwd(name:, container_name:, generate: false)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          user_name = "#{container_name}_#{name}"
          passwords = self._create_password(generate: generate)
          self._update_password(name: user_name, encrypted_password: passwords[:encrypted_password])
          generate ? { data: passwords[:password] } : {}
        else
          resp
        end
      end

      def delete(name:, container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? and
            (resp = self.existing_validation(name: name, container_name: container_name)).net_status_ok?
          container_lib_mapper = @lib.containers.f(container_name)
          passwd_mapper = container_lib_mapper.config.f('etc-passwd')
          user_name = "#{container_name}_#{name}"
          self._del(name: user_name)
          passwd_mapper.remove_line!(/^#{user_name}:.*/)
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
        user = self._get(name: container_name)
        self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: shell, home_dir: home_dir, uid: user.uid)
      end

      def _add_system_user(name:, container_name:, shell: '/usr/sbin/nologin', home_dir: "/web/#{container_name}")
        self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: shell, home_dir: home_dir)
      end

      def _add_custom(name:, group:, shell: '/usr/sbin/nologin', home_dir: "/web/#{group}", uid: nil)
        if (resp = self.adding_validation(name: name, container_name: group)).net_status_ok?
          container_lib_mapper = @lib.containers.f(group)
          passwd_mapper = container_lib_mapper.config.f('etc-passwd')

          useradd_command = "useradd #{name} -g #{group} -d #{home_dir} -s #{shell}".split
          useradd_command += "-u #{uid} -o".split unless uid.nil?
          self.command!(useradd_command, debug: false)

          user = self._get(name: name)

          self.with_dry_run do |dry_run|
            user_gid, user_uid = dry_run ? ['XXXX', 'XXXX'] : [user.gid, user.uid]
            passwd_mapper.append_line!("#{name}:x:#{user_uid}:#{user_gid}::#{home_dir}:#{shell}")
          end
        end
        resp
      end

      def _pretty_add_custom(name:, group:, shell: '/usr/sbin/nologin', home_dir: "/web/#{group}", uid: nil)
        self.debug_operation(desc: { code: :user, data: { name: name } }) do |&blk|
          if self._get(name: name)
            blk.call(code: :ok)
            {}
          else
            self._add_custom(name: name, group: group, shell: shell, home_dir: home_dir, uid: uid).tap do
              blk.call(code: :added)
            end
          end
        end
      end

      def _pretty_del(name:, group:)
        with_adding_group = self._group_get_users(name: group).one? ? true : false
        self._del(name: name)
        self._group_add(name: group) if with_adding_group
      end

      def _del(name:)
        self.debug_operation(desc: { code: :user, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            resp = self.command!("userdel #{name}", debug: false) unless dry_run
            blk.call(code: :deleted)
            resp
          end
        end
      end

      def _create_password(generate: false)
        password = if generate
          SecureRandom.hex
        else
          while 1
            if (pass = ask('Enter password: ') { |q| q.echo = false }) != ask('Repeat password: ') { |q| q.echo = false }
              self.info('Passwords does not match')
            elsif !StrongPassword::StrengthChecker.new(pass).is_strong?(min_entropy: @config.f('password_strength', default: '15').to_i)
              self.info('Password is weak')
            else
              break
            end
          end
          pass
        end
        encrypted_password = UnixCrypt::SHA512.build(password)
        { password: password, encrypted_password: encrypted_password }
      end

      def _update_password(name:, encrypted_password:)
        self.debug_operation(desc: { code: :user, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            resp = self.command!("usermod -p '#{encrypted_password}' #{name}", debug: false) unless dry_run
            blk.call(code: :updated)
            resp
          end
        end
      end

      def _group_get(name:)
        begin
          Etc.getgrnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _group_add(name:)
        self.debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            resp = self.command!("groupadd #{name}", debug: false) unless dry_run
            blk.call(code: :added)
            resp
          end
        end
      end

      def _group_pretty_add(name:)
        self._group_add(name: name) if self._group_get(name: name).nil?
      end

      def _group_del(name:)
        self.debug_operation(desc: { code: :group, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            resp = self.command!("groupdel #{name}", debug: false) unless dry_run
            blk.call(code: :deleted)
            resp
          end
        end
      end

      def _group_pretty_del(name:)
        self._group_del(name: name) unless self._group_get(name: name).nil?
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
          self._group_get_users(name: name).map {|u| u.name.slice(/(?<=#{name}_).*/) if u.uid != base_user.uid }.compact
        else
          []
        end
      end

      def _group_del_users(name:)
        self._group_get_users_names(name: name).each {|user| self._del(name: user) }
      end

      def adding_validation(name:, container_name:)
        return { error: :input_error, code: :invalid_user_name, data: { name: name, regex: USER_NAME_FORMAT } } if name !~ USER_NAME_FORMAT
        self.not_existing_validation(name: name, container_name: container_name)
      end

      def existing_validation(name:, container_name:)
        user_name = "#{container_name}_#{name}"
        PathMapper.new('/etc/passwd').check(user_name) ? {} : { error: :logical_error, code: :user_does_not_exists, data: { name: user_name } }
      end

      def not_existing_validation(name:, container_name:)
        self.existing_validation(name: name, container_name: container_name).net_status_ok? ? { error: :logical_error, code: :user_exists, data: { name: "#{container_name}_#{name}" } } : {}
      end
    end
  end
end