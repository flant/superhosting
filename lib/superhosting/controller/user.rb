module Superhosting
  module Controller
    class User < Base
      def initialize(**kwargs)
        super(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def list(container_name:)
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok?
          all_users = self._list(container_name: container_name)
          admins, users = all_users.partition { |u| self.admin?(name: u, container_name: container_name) }
          system_users, users = users.partition { |u| self.system?(name: u, container_name: container_name) }
          { data: [{ 'user' => users }, { 'admin' => admins }, { 'system' => system_users }] }
        else
          resp
        end
      end

      def _list(container_name:)
        self._group_get_users_names(name: container_name)
      end

      def add(name:, container_name:, ftp_dir: nil, ftp_only: false, generate: false)
        return { error: :logical_error, code: :option_ftp_only_is_required } if ftp_dir && !ftp_only

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
        if (resp = @container_controller.available_validation(name: container_name)).net_status_ok? &&
           (resp = self.existing_validation(name: name, container_name: container_name)).net_status_ok?
          container_lib_mapper = @lib.containers.f(container_name)
          passwd_mapper = container_lib_mapper.config.f('etc-passwd')
          user_name = "#{container_name}_#{name}"
          self._del(name: user_name, group: container_name)
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
    end
  end
end
