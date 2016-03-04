module Superhosting
  module Controller
    class Container < Base
      CONTAINER_NAME_FORMAT = /[a-zA-Z0-9][a-zA-Z0-9_.-]+/

      def list
        docker = @docker_api.container_list.map {|c| c['Names'].first.slice(1..-1) }.to_set
        sx = @config.containers._grep_dirs.map {|n| n._name }.to_set
        containers = (docker & sx)

        { data: containers.to_a }
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        if !(resp = self.adding_validation(name: name)).net_status_ok?
          return resp
        elsif (model_ = model || @config.default_model(default: nil)).nil?
          return { error: :input_error, message: 'No model given.' }
        end

        FileUtils.mkdir_p '/web'

        # config
        container_mapper = @config.containers.f(name)
        FileUtils.mkdir_p container_mapper._path

        # model
        file_write(container_mapper.model._path, model) unless model.nil?
        model_mapper = @config.models.f(:"#{model_}")

        # image
        return { error: :input_error, message: "No docker_image specified in model '#{model_}.'" } unless (image = model_mapper.docker_image(default: nil))

        # mail
        unless mail != 'no'
          if mail == 'yes'
            file_write(container_mapper.mail._path, mail)
            admin_mail_ = admin_mail
            file_write(container_mapper.admin_mail._path, admin_mail_) unless admin_mail_.nil?
          elsif mail == 'model'
            if model_mapper.default_mail == 'yes'
              admin_mail_ = admin_mail || model_mapper.default_admin_mail(default: nil)
            end
          end
          return { error: :input_error, message: 'Admin mail required.' } if defined? admin_mail_ and admin_mail_.nil?
        end

        # lib
        container_lib_mapper = @lib.containers.f(name)
        FileUtils.rm_rf container_lib_mapper.configs._path
        FileUtils.mkdir_p container_lib_mapper.configs._path
        FileUtils.mkdir_p container_lib_mapper.web._path
        self.command("ln -fs #{container_lib_mapper.web._path} /web/#{name}")

        # user / group
        user_controller = self.get_controller(User)
        user_controller._group_add(name: name)
        user_controller._add_custom(name: name, group: name)
        user = user_controller._get(name: name)
        pretty_write(container_lib_mapper.configs.f('etc-group')._path, "#{name}:x:#{user.gid}:")

        # system users
        users = [container_mapper.system_users, model_mapper.system_users].find {|f| f.is_a? PathMapper::FileNode }
        users.lines.each do |u|
          user_controller._add(name: u.strip, container_name: name)
        end unless users.nil?

        # chown
        FileUtils.chown_R name, name, container_lib_mapper.web._path

        # services
        # cserv = @config.containers.f(name).services._grep(/.*\.erb/).map {|n| [n._name, n]}.to_h
        mserv = model_mapper.services._grep(/.*\.erb/).map {|n| [n._name, n]}.to_h
        # services = mserv.merge!(cserv)
        services = mserv

        supervisor_path = container_lib_mapper.supervisor._path
        FileUtils.mkdir_p supervisor_path
        services.each do |_name, node|
          text = erb(node, model: model_, container: container_mapper)
          file_write("#{supervisor_path}/#{_name[/.*[^\.erb]/]}", text)
        end

        # container
        unless model_mapper.f('container.rb').nil?
          registry_path = container_lib_mapper.registry.f('container')._path
          ex = ScriptExecutor::Container.new(
              container: container_mapper, container_name: name, container_lib: container_lib_mapper, registry_path: registry_path,
              model: model_mapper, config: @config, lib: @lib
          )
          ex.execute(model_mapper.f('container.rb'))
          ex.commands.each {|c| self.command c }
        end

        # docker
        pretty_write('/etc/security/docker.conf', "@#{name} #{name}")

        # run container
        self.command "docker run --detach --name #{name} -v #{container_lib_mapper.configs._path}/:/.configs:ro
                      -v #{container_lib_mapper.web._path}:/web/#{name} #{image} /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf".split

        return { error: :error, message: 'Unable to run docker container.' } unless @docker_api.container_info(name)

        {}
      end

      def delete(name:)
        container_mapper = @config.containers.f(name)
        container_lib_mapper = @lib.containers.f(name)
        model = container_mapper.model(default: @config.default_model)
        model_mapper = @config.models.f(:"#{model}")

        if self.existing_validation(name: name).net_status_ok? and self.running_validation(name: name).net_status_ok?
          site_controller = self.get_controller(Site)
          sites = container_mapper.sites._grep_dirs.map { |n| n._name }
          sites.each {|s| site_controller.delete(name: s).net_status_ok! }

          unless (container = container_lib_mapper.registry.f('container')).nil?
            FileUtils.rm container.lines
            FileUtils.rm container._path
          end

          unless model_mapper.f('container.rb').nil?
            registry_path = container_lib_mapper.registry.f('container')._path
            ex = ScriptExecutor::Container.new(
                container: container_mapper, container_name: name, container_lib: container_lib_mapper,
                registry_path: registry_path, on_reconfig_only: true,
                model: model_mapper, config: @config, lib: @lib
            )
            ex.execute(model_mapper.f('container.rb'))
            ex.commands.each {|c| self.command c }
          end

          @docker_api.container_kill(name)
          @docker_api.container_rm(name)
          pretty_remove('/etc/security/docker.conf', "@#{name} #{name}")

          user_controller = self.get_controller(User)
          user_controller._del_group_users(name: name)

          FileUtils.rm_rf container_lib_mapper._path
          FileUtils.rm_rf container_mapper._path

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
        return { error: :input_error, message: "Invalid container name '#{name}' - only '#{CONTAINER_NAME_FORMAT}' are allowed" } if name !~ CONTAINER_NAME_FORMAT
        self.not_running_validation(name: name)
      end

      def running_validation(name:)
        self.not_running_validation(name: name).net_status_ok? ? { error: :logical_error, message: 'Container isn\'t running.' } : {}
      end

      def not_running_validation(name:)
        @docker_api.container_info(name).nil? ? {} : { error: :logical_error, message: 'Container already running.' }
      end

      def existing_validation(name:)
        (@lib.containers.f(name)).nil? ? { error: :logical_error, message: "Container '#{name}' doesn't exists" } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, message: "Container '#{name}' already exists" } : {}
      end
    end
  end
end
