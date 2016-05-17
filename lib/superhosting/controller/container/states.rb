module Superhosting
  module Controller
    class Container
      include Helper::States

      def stop_old_mux(name:, model:)
        if (existing_validation(name: name)).net_status_ok? && model && index[name][:model_name] != model
          stop_mux(name: name)
        else
          {}
        end
      end

      def install_data(name:, model: nil)
        if (model_ = model || @config.containers.f(name).f('model', default: @config.default_model)).nil?
          { error: :input_error, code: :no_model_given }
        else
          # model
          return { error: :input_error, code: :model_does_not_exists, data: { name: model_ } } unless @config.models.f(model_).dir?
          etc_mapper = @config.containers.f(name).create!
          etc_mapper.model.put!(model) unless model.nil?

          # config
          reindex_container(name: name)
          mapper = index[name][:mapper]

          # lib
          mapper.lib.config.create!
          mapper.lib.web.create!

          # web
          PathMapper.new('/web').create!
          safe_link!(mapper.lib.web.path, mapper.web.path)
          {}
        end
      end

      def uninstall_data(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          # lib
          safe_unlink!(mapper.web.path)
          mapper.lib = mapper.lib
          mapper.lib.web.delete!
          mapper.lib.config.delete!
          mapper.lib.delete!

          # config
          mapper.delete!

          reindex_container(name: name)
          {}
        else
          resp
        end
      end

      def install_users(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          # user / group
          mapper.lib.config.f('etc-group').append_line!('root:x:0:')
          mapper.lib.config.f('etc-passwd').append_line!('root:x:0:0:root:/root:/bin/bash')

          user_controller = controller(User)
          user_controller._group_add(name: name)
          unless (resp = user_controller._add_custom(name: name, group: name)).net_status_ok?
            return resp
          end
          user = user_controller._get(name: name)

          with_dry_run do |dry_run|
            user_gid = if dry_run
                         'XXXX' if user.nil?
                       else
                         user.gid
                       end

            mapper.lib.config.f('etc-group').append_line!("#{name}:x:#{user_gid}:") unless user_gid.nil?
          end

          # system users
          current_system_users = user_controller._group_get_system_users(name: name)
          add_users = mapper.system_users.lines - current_system_users
          del_users = current_system_users - mapper.system_users.lines
          add_users.each do |u|
            unless (resp = user_controller._add_system_user(name: u.strip, container_name: name)).net_status_ok?
              return resp
            end
          end
          del_users.each do |u|
            user_name = "#{name}_#{u.strip}"
            user = user_controller._get(name: user_name)
            unless (resp = user_controller._del(name: user_name, group: name)).net_status_ok?
              return resp
            end
            mapper.lib.config.f('etc-passwd').remove_line!(/^#{user_name}:.*/)
          end

          # docker
          PathMapper.new('/etc/security/docker.conf').append_line!("@#{name} #{name}")

          # chown
          chown_r!(name, name, mapper.lib.web.path)
          {}
        else
          resp
        end
      end

      def uninstall_users(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          user_controller = controller(User)
          if (user = user_controller._get(name: name))
            mapper.lib.config.f('etc-group').remove_line!("#{name}:x:#{user.gid}:")
          end

          user_controller._group_del_users(name: name)
          user_controller._group_del(name: name)

          # docker
          PathMapper.new('/etc/security/docker.conf').remove_line!("@#{name} #{name}")

          {}
        else
          resp
        end
      end

      def unconfigure(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, _state|
            controller.unconfigure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, _state|
            controller.apply(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def configure_with_apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, _state|
            controller.reconfigure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def run(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]
          _refresh_container(mapper: mapper, docker_options: _docker_options(mapper: mapper))
        else
          resp
        end
      end

      def _refresh_container(mapper:, docker_options: [])
        command_options, image, command = docker_options
        dump_command_option = (command_options + [command]).join("\n")
        dummy_signature_md5 = Digest::MD5.new.digest(dump_command_option)

        restart = (!mapper.docker.image.compare_with(mapper.lib.image) || (dummy_signature_md5 != mapper.lib.signature.md5))

        if (resp = _safe_run_docker(command_options, image, command, name: mapper.container_name, restart: restart)).net_status_ok?
          mapper.lib.image.put!(image, logger: false)
          mapper.lib.signature.put!(dump_command_option, logger: false)
          mapper.lib.docker_options.put!(Marshal.dump(docker_options), logger: false)
        end
        resp
      end

      def _docker_options(mapper:)
        command_options, image, command = _collect_docker_options(mapper: mapper).net_status_ok![:data]
        ["#{mapper.lib.web.path}:#{mapper.web.path}", "#{mapper.config.path}/:/.config:ro"].each { |v| command_options << "--volume #{v}" }
        [command_options, image, command]
      end

      def run_mux(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          resp = {}
          mapper = index[name][:mapper]

          if (mux_mapper = mapper.mux).file?
            mux_name = mux_mapper.value
            mux_controller = controller(Mux)
            mux_controller._reconfigure(name: mux_name)
            mux_controller.index_push_container(mux_name, name)
          end
        end

        resp
      end

      def stop_mux(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          if (mux_mapper = mapper.mux).file?
            mux_name = mux_mapper.value
            mux_controller = controller(Mux)
            mux_controller.index_pop_container(mux_name, name)
            mux_controller._delete(name: mux_name) if mux_controller.index_mux_containers(name: mux_name).empty?
          end
        end
        resp
      end

      def stop(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _delete_docker(name: name)
          controller(Mux).reindex
        end
        resp
      end

      def _config_options(name:, **_kwargs)
        mapper = index[name][:mapper]
        model = mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")
        mux_mapper = index[name][:mux_mapper]
        registry_mapper = mapper.lib.registry.f('container')
        super.merge!(container: mapper, mux: mux_mapper, model: model_mapper, registry_mapper: registry_mapper)
      end

      def _each_site(name:)
        site_controller = controller(Superhosting::Controller::Site)
        site_controller.reindex_container_sites(container_name: name)
        site_controller.container_sites(container_name: name).each do |site_name, index|
          yield site_controller, site_name, index[:state]
        end
      end
    end
  end
end
