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
        PathMapper.new('/web').create!
        safe_link!(mapper.lib.web.path, mapper.web.path)
        mapper.web.create!
        {}
      end

      def uninstall_data(name:)
        if self.index.include? name
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
        end

        {}
      end

      def install_users(name:)
        mapper = self.index[name][:mapper]

        # user / group
        user_controller = self.get_controller(User)
        user_controller._group_pretty_add(name: name)
        unless (resp = user_controller._pretty_add_custom(name: name, group: name)).net_status_ok?
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
          unless (resp = user_controller._del(name: user_name)).net_status_ok?
            return resp
          end
          mapper.lib.config.f('etc-passwd').remove_line!(/^#{user_name}:.*/)
        end

        # docker
        PathMapper.new('/etc/security/docker.conf').append_line!("@#{name} #{name}")

        # chown
        chown_r!(name, name, mapper.lib.web.path)
        {}
      end

      def uninstall_users(name:)
        mapper = self.index[name][:mapper]

        user_controller = self.get_controller(User)
        if (user = user_controller._get(name: name))
          mapper.lib.config.f('etc-group').remove_line!("#{name}:x:#{user.gid}:")
        end

        user_controller._group_del_users(name: name)
        user_controller._group_pretty_del(name: name)

        # docker
        PathMapper.new('/etc/security/docker.conf').remove_line!("@#{name} #{name}")

        {}
      end

      def configure(name:)
        self._each_site(name: name) do |controller, sname, state|
          controller.configure(name: sname).net_status_ok!
        end
        super
      end

      def unconfigure(name:)
        self._each_site(name: name) do |controller, sname, state|
          controller.unconfigure(name: sname).net_status_ok! # TODO: unchanged site status
        end
        super
      end

      def apply(name:)
        self._each_site(name: name) do |controller, sname, state|
          controller.apply(name: sname).net_status_ok!
        end
        super
      end

      def configure_with_apply(name:)
        self._each_site(name: name) do |controller, sname, state|
          controller.reconfigure(name: sname).net_status_ok!
        end
        super
      end

      def run(name:)
        mapper = self.index[name][:mapper]
        model = mapper.f('model', default: @config.default_model)

        return { error: :input_error, code: :no_docker_image_specified_in_model, data: { model: model } } if (image = mapper.docker.image).nil?

        command_options, command = self._docker_options(mapper: mapper)
        dump_command_option = Marshal.dump(command_options + [command])
        dummy_signature_md5 = Digest::MD5.new.digest(dump_command_option)

        restart = (!image.compare_with(mapper.lib.image) or (dummy_signature_md5 != mapper.lib.signature.md5))

        if (resp = self._run_docker(name: name, options: command_options, image: image, command: command, restart: restart)).net_status_ok?
          mapper.lib.image.put!(image, logger: false)
          mapper.lib.signature.put!(dump_command_option, logger: false)
        end

        resp
      end

      def run_mux(name:)
        resp = {}
        mapper = self.index[name][:mapper]

        if (mux_mapper = mapper.mux).file?
          mux_name = "mux-#{mux_mapper.value}"
          mux_controller = self.get_controller(Mux)
          resp = mux_controller.add(name: mux_name) if mux_controller.not_running_validation(name: mux_name).net_status_ok?
          mux_controller.index_push(mux_name, name)
        end

        resp
      end

      def stop_mux(name:)
        mapper = self.index[name][:mapper]

        if (mux_mapper = mapper.mux).file?
          mux_name = "mux-#{mux_mapper.value}"
          mux_controller = self.get_controller(Mux)
          mux_controller.index_pop(mux_name, name)
          unless mux_controller.index.include?(mux_name)
            @docker_api.container_kill!(mux_name)
            @docker_api.container_rm!(mux_name)
          end
        end

        {}
      end

      def stop(name:)
        @docker_api.container_kill!(name)
        @docker_api.container_rm!(name)
        self.get_controller(Mux).reindex
        {}
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

      def _docker_options(mapper:)
        all_options = mapper.docker.grep_files.map {|n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n] }.to_h
        command_options = @docker_api.grab_container_options(all_options)

        volume_opts = []
        mapper.docker.f('volume', overlay: false).each {|v| volume_opts += v.lines unless v.nil? }
        volume_opts.each {|val| command_options << "--volume #{val}" }

        [command_options, all_options[:command].value]
      end

      def _run_docker(name:, options:, image:, command:, restart: false)
        return { error: :logical_error, code: :docker_command_not_found } if command.nil?

        if restart
          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)
          @docker_api.container_run(name, options, image, command)
        elsif @docker_api.container_exists?(name)
          if @docker_api.container_dead?(name)
            @docker_api.container_kill!(name)
            @docker_api.container_rm!(name)
            @docker_api.container_run(name, options, image, command)
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
          @docker_api.container_run(name, options, image, command)
        end
        self.running_validation(name: name)
      end

      def _each_site(name:)
        site_controller = self.get_controller(Superhosting::Controller::Site)
        site_controller._list(container_name: name).each do |site|
          yield site_controller, site[:name], site[:state]
        end
      end
    end
  end
end