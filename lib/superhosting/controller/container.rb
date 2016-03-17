module Superhosting
  module Controller
    class Container < Base
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
        elsif (model_ = model || @config.containers.f(name, default: @config.default_model)).nil?
          return { error: :input_error, code: :no_model_given }
        end

        # model
        model_mapper = @config.models.f(:"#{model_}")
        return { error: :input_error, code: :model_does_not_exists, data: { name: model_ } } unless @config.models.f(:"#{model_}").dir?
        container_mapper = @config.containers.f(name)
        container_mapper.model.puts!(model) unless model.nil?

        # config
        container_mapper = ModelInheritance.new(container_mapper, model_mapper).get
        container_mapper.model.put!(model) unless model.nil?

        # web
        web_mapper = PathMapper.new('/web').create!
        container_web_mapper = web_mapper.f(name)

        # image
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
          unless (resp = user_controller._add(name: u.strip, container_name: name)).net_status_ok?
            return resp
          end
        end unless users.nil?

        # chown
        FileUtils.chown_R name, name, container_lib_mapper.web.path

        # services
        services = container_mapper.services.grep(/.*\.erb/).map {|n| [n.name, n]}.to_h

        supervisor_mapper = container_lib_mapper.supervisor
        supervisor_mapper.create!
        services.each do |_name, node|
          supervisor_mapper.f(_name[/.*[^\.erb]/]).put!(node) # TODO: FileNode.erb_options
        end

        # config.rb
        container_mapper.f('config.rb', overlay: false).reverse.each do |config|
          registry_mapper = container_lib_mapper.registry.f('container')
          ex = ScriptExecutor::Container.new(
              container_name: container_mapper.name,
              container: container_mapper,
              container_lib: container_lib_mapper,
              container_web: container_web_mapper,
              model: model_mapper,
              registry_mapper: registry_mapper,
              config: @config, lib: @lib
          )
          ex.execute(config)
          ex.commands.each {|c| self.command c }
        end

        # docker
        pretty_write('/etc/security/docker.conf', "@#{name} #{name}")

        # run container
        self.command "docker run --detach --name #{name} --entrypoint /usr/bin/supervisord -v #{container_lib_mapper.configs.path}/:/.configs:ro
                      -v #{container_lib_mapper.web.path}:/web/#{name} #{image} -nc /etc/supervisor/supervisord.conf".split

        if (resp = self.running_validation(name: name)).net_status_ok?
          {}
        else
          resp
        end
      end

      def delete(name:)
        container_mapper = @config.containers.f(name)
        model = container_mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")
        container_mapper = ModelInheritance.new(container_mapper, model_mapper).get
        container_lib_mapper = @lib.containers.f(name)
        container_web_mapper = PathMapper.new('/web').f(name)

        if self.existing_validation(name: name).net_status_ok? and self.running_validation(name: name).net_status_ok?
          site_controller = self.get_controller(Site)
          sites = container_mapper.sites.grep_dirs.map { |n| n.name }
          sites.each do |s|
            unless (resp = site_controller.delete(name: s)).net_status_ok?
              return resp
            end
          end

          unless (registry_container_mapper = container_lib_mapper.registry.f('container')).nil?
            FileUtils.rm_rf registry_container_mapper.lines
            registry_container_mapper.delete!
          end

          container_mapper.f('config.rb', overlay: false).reverse.each do |config|
            registry_mapper = container_lib_mapper.registry.f('container')
            ex = ScriptExecutor::Container.new(
                container_name: container_mapper.name,
                container: container_mapper,
                container_lib: container_lib_mapper,
                container_web: container_web_mapper,
                model: model_mapper,
                registry_mapper: registry_mapper,
                on_reconfig_only: true,
                config: @config, lib: @lib,
            )
            ex.execute(config)
            ex.commands.each {|c| self.command c }
          end

          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)
          pretty_remove('/etc/security/docker.conf', "@#{name} #{name}")

          user_controller = self.get_controller(User)
          user_controller._group_del_users(name: name)
          user_controller._group_del(name: name)

          container_lib_mapper.delete!(full: true)
          container_mapper.delete!(full: true)

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

      end

      def save(name:, to:)

      end

      def restore(name:, from:, mail: 'model', admin_mail: nil, model: nil)

      end

      def admin(name:)
        self.get_controller(Admin, name: name)
      end

      def adding_validation(name:)
        @docker_api.remove_inactive_container!(name)
        return { error: :input_error, code: :invalid_container_name, data: { name: name, regex: CONTAINER_NAME_FORMAT } } if name !~ CONTAINER_NAME_FORMAT
        self.not_running_validation(name: name)
      end

      def running_validation(name:)
        self.not_running_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_is_not_running, data: { name: name} } : {}
      end

      def not_running_validation(name:)
        @docker_api.container_running?(name) ? { error: :logical_error, code: :container_is_running, data: { name: name } } : {}
      end

      def existing_validation(name:)
        (@lib.containers.f(name)).nil? ? { error: :logical_error, code: :container_does_not_exists, data: { name: name }  } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_exists, data: { name: name }  } : {}
      end
    end
  end
end
