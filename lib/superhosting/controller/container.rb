module Superhosting
  module Controller
    class Container < Base
      attr_writer :contianer_index
      CONTAINER_NAME_FORMAT = /^[a-zA-Z0-9][a-zA-Z0-9_.-]+$/

      def list
        docker = @docker_api.container_list.map {|c| c['Names'].first.slice(1..-1) }.to_set
        sx = @config.containers.grep_dirs.map {|n| n.name }.to_set
        containers = (docker & sx)

        { data: containers.to_a }
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        if !(resp = self.adding_validation(name: name)).net_status_ok?
          return resp
        elsif (model_ = model || @config.containers.f(name).f('model', default: @config.default_model)).nil?
          return { error: :input_error, code: :no_model_given }
        end

        # model
        model_mapper = @config.models.f(model_)
        return { error: :input_error, code: :model_does_not_exists, data: { name: model_ } } unless @config.models.f(model_).dir?
        container_mapper = @config.containers.f(name).create!
        container_mapper.model.put!(model) unless model.nil?

        # config
        self.reindex_container(name)
        container_mapper = self.container_index[name][:mapper]

        # web
        web_mapper = PathMapper.new('/web').create!
        container_web_mapper = web_mapper.f(name)

        return { error: :input_error, code: :no_docker_image_specified_in_model, data: { model: model_} } if (image = container_mapper.docker.image).nil?

        # mail
        unless mail != 'no'
          if mail == 'yes'
            container_mapper.mail.put!(mail)
            unless (admin_mail_ = admin_mail).nil?
              container_mapper.admin_mail.put!(admin_mail_)
            end
          elsif mail == 'model'
            if model_mapper.default_mail == 'yes'
              admin_mail_ = admin_mail || model_mapper.default_admin_mail
            end
          end
          return { error: :input_error, code: :option_admin_mail_required } if defined? admin_mail_ and admin_mail_.nil?
        end

        # lib
        container_lib_mapper = @lib.containers.f(name)
        container_lib_mapper.configs.delete!
        container_lib_mapper.configs.create!
        container_lib_mapper.web.create!
        self.command("ln -fs #{container_lib_mapper.web.path} #{container_web_mapper.path}")

        # user / group
        user_controller = self.get_controller(User)
        user_controller._group_add(name: name)
        unless (resp = user_controller._add_custom(name: name, group: name)).net_status_ok?
          return resp
        end
        user = user_controller._get(name: name)
        pretty_write(container_lib_mapper.configs.f('etc-group').path, "#{name}:x:#{user.gid}:")

        # system users
        users = container_mapper.system_users
        users.lines.each do |u|
          unless (resp = user_controller._add_system_user(name: u.strip, container_name: name)).net_status_ok?
            return resp
          end
        end unless users.nil?

        # chown
        FileUtils.chown_R name, name, container_lib_mapper.web.path

        # services
        services = container_mapper.services.grep(/.*\.erb/)
        supervisor_mapper = container_lib_mapper.supervisor.create!
        services.each {|node| supervisor_mapper.f(node.name[/.*[^\.erb]/]).put!(node) }

        # config.rb
        self._config(name)

        # docker
        container_mapper.erb_options = { container: container_mapper }
        all_options = container_mapper.docker.grep_files.map {|n| [n.name[/.*[^\.erb]/].to_sym, n] }.to_h
        command_options = @docker_api.grab_container_options(all_options)

        volume_opts = ["#{container_lib_mapper.configs.path}/:/.configs:ro", "#{container_lib_mapper.web.path}:/web/#{name}"]
        volume_opts << all_options[:volume].lines unless all_options[:volume].nil?
        volume_opts.each {|val| command_options << "--volume #{val}" }

        if (resp = self._run_docker(name: name, options: command_options, image: image, command: all_options[:command])).net_status_ok?
          if (mux_mapper = container_mapper.mux).file?
            mux_name = mux_mapper.value
            @mux_controller = self.get_controller(Mux)
            unless @docker_api.container_running?(mux_name)
              resp = @mux_controller.add(name: mux_name)
            end
            @mux_controller.mux_index_push(mux_name, name)
          end
        end
        resp
      end

      def delete(name:)
        def rm_docker_container(name)
          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)

          pretty_remove('/etc/security/docker.conf', "@#{name} #{name}")
        end

        if self.existing_validation(name: name).net_status_ok? and self.running_validation(name: name).net_status_ok?
          container_lib_mapper = @lib.containers.f(name)
          container_mapper = self.container_index[name][:mapper]
          web_mapper = PathMapper.new("/web").f(name)

          self._config_rollback(name)

          site_controller = self.get_controller(Site)
          sites = container_mapper.sites.grep_dirs.map { |n| n.name }
          sites.each do |s|
            unless (resp = site_controller.delete(name: s)).net_status_ok?
              return resp
            end
          end
          container_lib_mapper.web.delete!
          self.command("unlink #{web_mapper.path}")

          unless (registry_container_mapper = container_lib_mapper.registry.f('container')).nil?
            FileUtils.rm_rf registry_container_mapper.lines
            registry_container_mapper.delete!
          end

          rm_docker_container(name)
          if (mux_mapper = container_mapper.mux).file?
            mux_name = mux_mapper.value
            @mux_controller = self.get_controller(Mux)
            @mux_controller.mux_index_pop(mux_name, name)
            rm_docker_container(mux_name) unless @mux_controller.mux_index.include?(mux_name)
          end

          user_controller = self.get_controller(User)
          user_controller._group_del_users(name: name)
          user_controller._group_del(name: name)

          container_lib_mapper.delete!(full: true)
          container_mapper.delete!(full: true)
          self.reindex_container(name)

          {}
        else
          self.debug("Container '#{name}' has already been deleted")
        end
      end

      def change(name:, mail: 'model', admin_mail: nil, model: nil)

      end

      def update(name:)

      end

      def reconfig(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok? and (resp = self.running_validation(name: name)).net_status_ok?
          container_mapper = self.container_index[name][:mapper]

          self._reconfig(name)

          site_controller = self.get_controller(Site)
          sites = container_mapper.sites.grep_dirs.map { |n| n.name }
          sites.each do |s|
            unless (resp = site_controller.reconfig(name: s)).net_status_ok?
              return resp
            end
          end
        end
        resp
      end

      def save(name:, to:)

      end

      def restore(name:, from:, mail: 'model', admin_mail: nil, model: nil)

      end

      def admin(name:)
        self.get_controller(Admin, name: name)
      end

      def model
        self.get_controller(Model)
      end

      def _config(container_name, on_reconfig_only: false)
        container_mapper = self.container_index[container_name][:mapper]
        container_mapper.f('config.rb', overlay: false).reverse.each do |config|
          ex = ScriptExecutor::Container.new(self._config_options(container_mapper, on_reconfig_only: on_reconfig_only))
          ex.execute(config)
          ex.commands.each {|c| self.command c }
        end
      end

      def _config_rollback(container_name)
        _config(container_name, on_reconfig_only: true)
      end

      def _reconfig(container_name)
        _config_rollback(container_name)
        _config(container_name)
      end

      def _config_options(container_mapper, on_reconfig_only:)
        container_name = container_mapper.name
        model = container_mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")
        container_lib_mapper = @lib.containers.f(container_name)
        container_web_mapper = PathMapper.new('/web').f(container_name)
        registry_mapper = container_lib_mapper.registry.f('container')
        mux_mapper = self.container_index[container_name][:mux_mapper]

        {
            container_name: container_name,
            container: container_mapper,
            container_lib: container_lib_mapper,
            container_web: container_web_mapper,
            mux: mux_mapper,
            model: model_mapper,
            registry_mapper: registry_mapper,
            on_reconfig_only: on_reconfig_only,
            etc: @config,
            lib: @lib,
            docker_api: @docker_api
        }
      end

      def _run_docker(name:, options:, image:, command:)
        pretty_write('/etc/security/docker.conf', "@#{name} #{name}")
        raise NetStatus::Exception, { error: :logical_error, code: :docker_command_not_found } if command.nil?
        @docker_api.container_run("docker run --detach --name #{name} #{options.join(' ')} #{image} #{command}")
        self.running_validation(name: name)
      end

      def base_validation(name:)
        @docker_api.container_rm_inactive!(name)
        (name !~ CONTAINER_NAME_FORMAT) ? { error: :input_error, code: :invalid_container_name, data: { name: name, regex: CONTAINER_NAME_FORMAT } } : {}
      end

      def adding_validation(name:)
        if (resp = self.base_validation(name: name)).net_status_ok?
          resp = self.not_running_validation(name: name)
        end
        resp
      end

      def running_validation(name:)
        @docker_api.container_running?(name) ? {}: { error: :logical_error, code: :container_is_not_running, data: { name: name } }
      end

      def not_running_validation(name:)
        @docker_api.container_not_running?(name) ? {} : { error: :logical_error, code: :container_is_running, data: { name: name } }
      end

      def existing_validation(name:)
        self.container_index.include?(name) ? {} : { error: :logical_error, code: :container_does_not_exists, data: { name: name }  }
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_exists, data: { name: name }  } : {}
      end

      def container_index
        def generate
          @config.containers.grep_dirs.each {|mapper| self.reindex_container(mapper.name) }
          @container_index ||= {}
        end

        @container_index || generate
      end

      def reindex_container(container_name)
        @container_index ||= {}
        container_mapper = @config.containers.f(container_name)

        if container_mapper.nil?
          @container_index.delete(container_name)
          return
        end

        model = container_mapper.f('model', default: @config.default_model)
        model_mapper = @config.models.f(model)
        container_mapper = MapperInheritance::Model.new(container_mapper, model_mapper).get
        container_mapper.erb_options = { container: container_mapper }
        mux_mapper = if (mux_file_mapper = container_mapper.mux).file?
          MapperInheritance::Mux.new(@config.muxs.f(mux_file_mapper)).get
        end

        @container_index[container_name] = {
            mapper: container_mapper,
            mux_mapper: mux_mapper,
        }
      end
    end
  end
end
