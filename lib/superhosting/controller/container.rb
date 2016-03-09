module Superhosting
  module Controller
    class Container < Base
      CONTAINER_NAME_FORMAT = /[a-zA-Z0-9][a-zA-Z0-9_.-]+/

      def list
        docker = @docker_api.container_list.map {|c| c['Names'].first.slice(1..-1) }.to_set
        sx = @config.containers.grep_dirs.map {|n| n.name }.to_set
        containers = (docker & sx)

        { data: containers.to_a }
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        if !(resp = self.adding_validation(name: name)).net_status_ok?
          return resp
        elsif (model_ = model || @config.default_model.value).nil?
          return { error: :input_error, code: :no_model_given }
        end

        FileUtils.mkdir_p '/web'

        # config
        container_mapper = @config.containers.f(name)
        container_mapper.create!

        # model
        container_mapper.model.put!(model) unless model.nil?
        model_mapper = @config.models.f(:"#{model_}")

        # image
        return { error: :input_error, code: :no_docker_image_specified_in_model, data: { model: model_} } unless (image = model_mapper.docker_image.value)

        # mail
        unless mail != 'no'
          if mail == 'yes'
            container_mapper.mail.put!(mail)
            unless (admin_mail_ = admin_mail).nil?
              container_mapper.admin_mail.put!(admin_mail_)
            end
          elsif mail == 'model'
            if model_mapper.default_mail == 'yes'
              admin_mail_ = admin_mail || model_mapper.default_admin_mail.value
            end
          end
          return { error: :input_error, code: :admin_mail_required } if defined? admin_mail_ and admin_mail_.nil?
        end

        # lib
        container_lib_mapper = @lib.containers.f(name)
        container_lib_mapper.configs.delete!
        container_lib_mapper.configs.create!
        container_lib_mapper.web.create!
        self.command("ln -fs #{container_lib_mapper.web.path} /web/#{name}")

        # user / group
        user_controller = self.get_controller(User)
        user_controller._group_add(name: name)
        unless (resp = user_controller._add_custom(name: name, group: name)).net_status_ok?
          return resp
        end
        user = user_controller._get(name: name)
        pretty_write(container_lib_mapper.configs.f('etc-group').path, "#{name}:x:#{user.gid}:")

        # system users
        users = [container_mapper.system_users, model_mapper.system_users].find {|f| f.file? }
        users.lines.each do |u|
          unless (resp = user_controller._add(name: u.strip, container_name: name)).net_status_ok?
            return resp
          end
        end unless users.nil?

        # chown
        FileUtils.chown_R name, name, container_lib_mapper.web.path

        # services
        # cserv = @config.containers.f(name).services.grep(/.*\.erb/).map {|n| [n.name, n]}.to_h
        mserv = model_mapper.services.grep(/.*\.erb/).map {|n| [n.name, n]}.to_h
        # services = mserv.merge!(cserv)
        services = mserv

        supervisor_path = container_lib_mapper.supervisor
        supervisor_path.create!
        services.each do |_name, node|
          text = erb(node, model: model_, container: container_mapper)
          file_write("#{supervisor_path}/#{_name[/.*[^\.erb]/]}", text)
        end

        # container
        unless model_mapper.f('container.rb').nil?
          registry_path = container_lib_mapper.registry.f('container').path
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
        self.command "docker run --detach --name #{name} --entrypoint /usr/bin/supervisord -v #{container_lib_mapper.configs.path}/:/.configs:ro
                      -v #{container_lib_mapper.web.path}:/web/#{name} #{image} -nc /etc/supervisor/supervisord.conf".split

        unless (resp = self.running_validation(name: name)).net_status_ok?
          return resp
        end

        {}
      end

      def delete(name:)
        container_mapper = @config.containers.f(name)
        container_lib_mapper = @lib.containers.f(name)
        model = container_mapper.model(default: @config.default_model).value
        model_mapper = @config.models.f(:"#{model}")

        if self.existing_validation(name: name).net_status_ok? and self.running_validation(name: name).net_status_ok?
          site_controller = self.get_controller(Site)
          sites = container_mapper.sites.grep_dirs.map { |n| n.name }
          sites.each do |s|
            unless (resp = site_controller.delete(name: s)).net_status_ok?
              return resp
            end
          end

          unless (container = container_lib_mapper.registry.f('container')).nil?
            FileUtils.rm container.lines
            container.delete!
          end

          unless model_mapper.f('container.rb').nil?
            registry_path = container_lib_mapper.registry.f('container').path
            ex = ScriptExecutor::Container.new(
                container: container_mapper, container_name: name, container_lib: container_lib_mapper,
                registry_path: registry_path, on_reconfig_only: true,
                model: model_mapper, config: @config, lib: @lib
            )
            ex.execute(model_mapper.f('container.rb'))
            ex.commands.each {|c| self.command c }
          end

          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)
          pretty_remove('/etc/security/docker.conf', "@#{name} #{name}")

          user_controller = self.get_controller(User)
          user_controller._group_del_users(name: name)

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
        @docker_api.container_running?(name) ? { error: :logical_error, code: :container_is_already_running, data: { name: name } } : {}
      end

      def existing_validation(name:)
        (@lib.containers.f(name)).nil? ? { error: :logical_error, code: :container_does_not_exists, data: { name: name }  } : {}
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :container_already_exists, data: { name: name }  } : {}
      end
    end
  end
end
