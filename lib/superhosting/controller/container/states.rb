module Superhosting
  module Controller
    class Container
      include Helper::States

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

      def install_users(name:, model:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          # user / group
          user_controller = get_controller(User)
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

          user_controller = get_controller(User)
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

      def configure(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, state|
            controller.configure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def unconfigure(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, state|
            controller.unconfigure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, state|
            controller.apply(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def configure_with_apply(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _each_site(name: name) do |controller, site_name, state|
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

          if (resp = _collect_docker_options(mapper: mapper)).net_status_ok?
            docker_options = resp[:data]
            command_options, image, command = docker_options
            dump_command_option = (command_options + [command]).join("\n")
            dummy_signature_md5 = Digest::MD5.new.digest(dump_command_option)

            restart = (!mapper.docker.image.compare_with(mapper.lib.image) || (dummy_signature_md5 != mapper.lib.signature.md5))

            if (resp = _safe_run_docker(command_options, image, command, name: name, restart: restart)).net_status_ok?
              mapper.lib.image.put!(image, logger: false)
              mapper.lib.signature.put!(dump_command_option, logger: false)
              mapper.lib.docker_options.put!(Marshal.dump(docker_options), logger: false)
            end
          end
        end
        resp
      end

      def run_mux(name:)
        resp = {}
        mapper = index[name][:mapper]

        if (mux_mapper = mapper.mux).file?
          mux_name = mux_mapper.value
          mux_controller = get_controller(Mux)
          resp = mux_controller.add(name: mux_name) if mux_controller.not_running_validation(name: mux_name).net_status_ok?
          mux_controller.index_push(mux_name, name)
        end

        resp
      end

      def stop_mux(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = index[name][:mapper]

          if (mux_mapper = mapper.mux).file?
            mux_name = mux_mapper.value
            mux_controller = get_controller(Mux)
            mux_controller.index_pop(mux_name, name)
            mux_controller._delete(name: mux_name) unless mux_controller.index.include?(mux_name)
          end
        end
        resp
      end

      def stop(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          _delete_docker(name: name)
          get_controller(Mux).reindex
        end
        resp
      end

      def _config_options(name:, on_reconfig:, on_config:)
        mapper = index[name][:mapper]
        model = mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")
        registry_mapper = mapper.lib.registry.f('container')
        mux_mapper = index[name][:mux_mapper]

        {
          container: mapper,
          mux: mux_mapper,
          model: model_mapper,
          registry_mapper: registry_mapper,
          on_reconfig: on_reconfig,
          on_config: on_config,
          etc: @config,
          lib: @lib,
          docker_api: @docker_api
        }
      end

      def _each_site(name:)
        site_controller = get_controller(Superhosting::Controller::Site)
        site_controller.reindex_container_sites(container_name: name)
        site_controller.container_sites(container_name: name).each do |site_name, index|
          yield site_controller, site_name, index[:state]
        end
      end
    end
  end
end
