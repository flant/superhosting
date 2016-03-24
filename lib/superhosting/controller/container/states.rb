module Superhosting
  module Controller
    class Container
      include Helper::States

      def install_data(name:, mail: 'model', admin_mail: nil, model: nil)
        if !(resp = self.adding_validation(name: name)).net_status_ok?
          return resp
        elsif (model_ = model || @config.containers.f(name).f('model', default: @config.default_model)).nil?
          return { error: :input_error, code: :no_model_given }
        end

        # model
        model_mapper = @config.models.f(model_)
        return { error: :input_error, code: :model_does_not_exists, data: { name: model_ } } unless @config.models.f(model_).dir?
        etc_mapper = @config.containers.f(name).create!
        etc_mapper.model.put!(model) unless model.nil?

        # config
        self.reindex_container(name: name)
        mapper = self.index[name][:mapper]

        # mail
        unless mail != 'no'
          if mail == 'yes'
            mapper.mail.put!(mail)
            unless (admin_mail_ = admin_mail).nil?
              mapper.admin_mail.put!(admin_mail_)
            end
          elsif mail == 'model'
            if model_mapper.default_mail == 'yes'
              admin_mail_ = admin_mail || model_mapper.default_admin_mail
            end
          end
          return { error: :input_error, code: :option_admin_mail_required } if defined? admin_mail_ and admin_mail_.nil?
        end

        # lib
        mapper.lib.config.delete!
        mapper.lib.config.create!
        mapper.lib.web.create!

        # web
        file_safe_link(mapper.lib.web.path, mapper.web.path)
        mapper.web.create!
        {}
      end

      def uninstall_data(name:)
        if self.index.include? name
          mapper = self.index[name][:mapper]

          # lib
          file_safe_unlink(mapper.web.path)
          mapper.lib = mapper.lib
          mapper.lib.web.delete!
          mapper.lib.config.delete!
          mapper.lib.delete!

          # config
          mapper.delete!

          self.reindex_container(name: name)
        end

        {}
      end

      def install_users(name:)
        mapper = self.index[name][:mapper]

        # user / group
        user_controller = self.get_controller(User)
        user_controller._group_pretty_add(name: name)
        unless (resp = user_controller._add_custom(name: name, group: name)).net_status_ok?
          return resp
        end
        user = user_controller._get(name: name)
        mapper.lib.config.f('etc-group').safe_append!("#{name}:x:#{user.gid}:")

        # system users
        users = mapper.system_users
        users.lines.each do |u|
          unless (resp = user_controller._add_system_user(name: u.strip, container_name: name)).net_status_ok?
            return resp
          end
        end unless users.nil?

        # chown
        chown_r(name, name, mapper.lib.web.path)
        {}
      end

      def uninstall_users(name:)
        mapper = self.index[name][:mapper]

        user_controller = self.get_controller(User)
        user = user_controller._get(name: name)
        pretty_remove(mapper.lib.config.f('etc-group').path, "#{name}:x:#{user.gid}:")

        user_controller._group_del_users(name: name)
        user_controller._group_pretty_del(name: name)

        {}
      end

      def configure(name:)
        self._config(name: name, on_reconfig: false, on_config: true)
        {}
      end

      def unconfigure(name:)
        mapper = self.index[name][:mapper]

        site_controller = self.get_controller(Site)
        sites = mapper.sites.grep_dirs.map { |n| n.name }
        sites.each do |site_name|
          unless (resp = site_controller.unconfigure(name: site_name)).net_status_ok?
            return resp
          end
        end

        unless (registry_container_mapper = mapper.lib.registry.f('container')).nil?
          registry_container_mapper.lines.each {|path| PathMapper.new(path).delete! }
          registry_container_mapper.delete!
        end

        {}
      end

      def apply(name:)
        self._config(name: name, on_reconfig: true, on_config: false)

        {}
      end

      def unapply(name:)
        apply(name: name)

        {}
      end

      def run(name:)
        mapper = self.index[name][:mapper]

        return { error: :input_error, code: :no_docker_image_specified_in_model, data: { model: model_} } if (image = mapper.docker.image).nil?

        all_options = mapper.docker.grep_files.map {|n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n] }.to_h
        command_options = @docker_api.grab_container_options(all_options)

        volume_opts = []
        mapper.docker.f('volume', overlay: false).each {|v| volume_opts += v.lines unless v.nil? }
        volume_opts.each {|val| command_options << "--volume #{val}" }

        if (resp = self._run_docker(name: name, options: command_options, image: image, command: all_options[:command])).net_status_ok?
          if (mux_mapper = mapper.mux).file?
            mux_name = mux_mapper.value
            @mux_controller = self.get_controller(Mux)
            unless @docker_api.container_running?(mux_name)
              resp = @mux_controller.add(name: mux_name)
            end
            @mux_controller.index_push(mux_name, name)
          end
        end
        resp
      end

      def stop(name:)
        mapper = self.index[name][:mapper]

        self._stop_docker(name)
        if (mux_mapper = mapper.mux).file?
          mux_name = mux_mapper.value
          @mux_controller = self.get_controller(Mux)
          @mux_controller.index_pop(mux_name, name)
          self._stop_docker(mux_name) unless @mux_controller.index.include?(mux_name)
        end
        {}
      end

      def _config(name:, on_reconfig:, on_config:)
        mapper = self.index[name][:mapper]
        mapper.f('config.rb', overlay: false).reverse.each do |config|
          ex = ScriptExecutor::Container.new(self._config_options(name: name, on_reconfig: on_reconfig, on_config: on_config))
          ex.execute(config)
          ex.run_commands
        end
      end

      def _reconfig(name:)
        self.unconfigure(name: name)
        self.configure(name: name)
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

      def _run_docker(name:, options:, image:, command:)
        pretty_write('/etc/security/docker.conf', "@#{name} #{name}")
        return { error: :logical_error, code: :docker_command_not_found } if command.nil?
        @docker_api.container_run(name, options, image, command)
        self.running_validation(name: name)
      end

      def _stop_docker(name)
        @docker_api.container_kill!(name)
        @docker_api.container_rm!(name)

        pretty_remove('/etc/security/docker.conf', "@#{name} #{name}")
      end
    end
  end
end