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
          self.reindex_container(name: name)
          mapper = self.index[name][:mapper]

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
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]

          # lib
          safe_unlink!(mapper.web.path)
          mapper.lib = mapper.lib
          mapper.lib.web.delete!
          mapper.lib.config.delete!
          mapper.lib.delete!

          # config
          mapper.delete!

          self.reindex_container(name: name)
          {}
        else
          resp
        end
      end

      def install_users(name:, model:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]

          # user / group
          user_controller = self.get_controller(User)
          user_controller._group_add(name: name)
          unless (resp = user_controller._add_custom(name: name, group: name)).net_status_ok?
            return resp
          end
          user = user_controller._get(name: name)

          self.with_dry_run do |dry_run|
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
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]

          user_controller = self.get_controller(User)
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
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._each_site(name: name) do |controller, site_name, state|
            controller.configure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def unconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._each_site(name: name) do |controller, site_name, state|
            controller.unconfigure(name: site_name).net_status_ok! # TODO: unchanged site status
          end
          super
        else
          resp
        end
      end

      def apply(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._each_site(name: name) do |controller, site_name, state|
            controller.apply(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def configure_with_apply(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._each_site(name: name) do |controller, site_name, state|
            controller.reconfigure(name: site_name).net_status_ok!
          end
          super
        else
          resp
        end
      end

      def run(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]

          if (resp = self._collect_docker_options(mapper: mapper)).net_status_ok?
            docker_options = resp[:data]
            command_options, image, command = docker_options
            dump_command_option = (command_options + [command]).join("\n")
            dummy_signature_md5 = Digest::MD5.new.digest(dump_command_option)

            restart = (!mapper.docker.image.compare_with(mapper.lib.image) or (dummy_signature_md5 != mapper.lib.signature.md5))

            if (resp = self._safe_run_docker(command_options, image, command, name: name, restart: restart)).net_status_ok?
              mapper.lib.image.put!(image, logger: false)
              mapper.lib.signature.put!(dump_command_option, logger: false)
              mapper.lib.docker_options.put!(Marshal.dump(docker_options))
            end
          end
          resp
        else
          resp
        end
      end

      def run_mux(name:)
        resp = {}
        mapper = self.index[name][:mapper]

        if (mux_mapper = mapper.mux).file?
          mux_name = mux_mapper.value
          mux_controller = self.get_controller(Mux)
          resp = mux_controller.add(name: mux_name) if mux_controller.not_running_validation(name: mux_name).net_status_ok?
          mux_controller.index_push(mux_name, name)
        end

        resp
      end

      def stop_mux(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mapper = self.index[name][:mapper]

          if (mux_mapper = mapper.mux).file?
            mux_name = mux_mapper.value
            mux_controller = self.get_controller(Mux)
            mux_controller.index_pop(mux_name, name)
            mux_controller._delete(name: mux_name) unless mux_controller.index.include?(mux_name)
          end
        end
        resp
      end

      def stop(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self._delete_docker(name: name)
          self.get_controller(Mux).reindex
        end
        resp
      end

      def _config_options(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        model = mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")
        registry_mapper = mapper.lib.registry.f('container')
        mux_mapper = self.index[name][:mux_mapper]

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

      def _delete_docker(name:)
        if @docker_api.container_exists?(name)
          @docker_api.container_unpause!(name) if @docker_api.container_paused?(name)
          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)
        end
      end

      def _recreate_docker(*docker_options, name:)
        docker_options ||= self._collect_docker_options(mapper: self.index[name][:mapper]).net_status_ok!
        self._delete_docker(name: name)
        self._run_docker(*docker_options, name: name)
      end

      def _run_docker(*docker_options, name:)
        docker_options = self._collect_docker_options(mapper: self.index[name][:mapper]).net_status_ok![:data] if docker_options.empty?
        @docker_api.container_run(name, *docker_options)
      end

      def _safe_run_docker(*docker_options, name:, restart: false)
        if restart
          self._recreate_docker(*docker_options, name: name)
        elsif @docker_api.container_exists?(name)
          if @docker_api.container_dead?(name)
            self._recreate_docker(*docker_options, name: name)
          elsif @docker_api.container_exited?(name)
            @docker_api.container_start!(name)
          elsif @docker_api.container_paused?(name)
            @docker_api.container_unpause!(name)
          elsif @docker_api.container_restarting?(name)
            Polling.start 10 do
               break unless @docker_api.container_restarting?(name)
               sleep 2
            end
          end
        else
          self._run_docker(*docker_options, name: name)
        end
        self.running_validation(name: name)
      end

      def _collect_docker_options(mapper:, model_or_mux: nil)
        model_or_mux ||= mapper.f('model', default: @config.default_model)
        return { error: :input_error, code: :no_docker_image_specified_in_model_or_mux, data: { name: model_or_mux } } if (image = mapper.docker.image).nil?

        all_options = mapper.docker.grep_files.map {|n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n.value] }.to_h
        return { error: :logical_error, code: :docker_command_not_found } if (command = all_options[:command]).nil?

        command_options = @docker_api.grab_container_options(all_options)
        volume_opts = []
        mapper.docker.f('volume', overlay: false).each {|v| volume_opts += v.lines unless v.nil? }
        volume_opts.each {|val| command_options << "--volume #{val}" }

        { data: [command_options, image.value, command] }
      end

      def _each_site(name:)
        site_controller = self.get_controller(Superhosting::Controller::Site)
        site_controller.reindex_container_sites(container_name: name)
        site_controller.container_sites(container_name: name).each do |site_name, index|
          yield site_controller, site_name, index[:state]
        end
      end
    end
  end
end