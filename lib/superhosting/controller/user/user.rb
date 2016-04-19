module Superhosting
  module Controller
    class User
      def _get(name:)
        begin
          Etc.getpwnam(name)
        rescue ArgumentError => e
          nil
        end
      end

      def _add(name:, container_name:, shell: '/usr/sbin/nologin', home_dir: "/web/#{container_name}")
        user = self._get(name: container_name)
        self.with_dry_run do |dry_run|
          user_uid = dry_run ? 'XXXX' : user.uid
          self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: shell, home_dir: home_dir, uid: user_uid)
        end
      end

      def _add_system_user(name:, container_name:)
        self._add_custom(name: "#{container_name}_#{name}", group: container_name, shell: '/usr/sbin/nologin', home_dir: "/web/#{container_name}")
      end

      def _add_custom(name:, group:, shell: '/usr/sbin/nologin', home_dir: "/web/#{group}", uid: nil)
        self.debug_operation(desc: { code: :user, data: { name: name } }) do |&blk|
          if self._get(name: name)
            blk.call(code: :ok)
            {}
          else
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
            blk.call(code: :added)
            resp
          end
        end
      end

      def _del(name:, group:)
        self.debug_operation(desc: { code: :user, data: { name: name } }) do |&blk|
          self.with_dry_run do |dry_run|
            resp = {}
            with_adding_group = self._group_get_users(name: group).one? ? true : false
            resp = self.command!("userdel #{name}", debug: false) unless dry_run
            self._group_add(name: group) if with_adding_group
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

      def system?(name:, container_name:)
        if (base_user = self._get(name: container_name)) and (user = self._get(name: name))
          base_user.uid != user.uid
        else
          false
        end
      end

      def admin?(name:, container_name:)
        name.include?('_admin_')
      end
    end
  end
end