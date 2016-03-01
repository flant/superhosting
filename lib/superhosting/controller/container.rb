module Superhosting
  module Controller
    class Container < Base
      def list
        docker = @docker_api.container_list.map {|c| c['Names'].first.slice(1..-1) }.to_set
        sx = @config.containers._grep(/.*/).map {|n| n._name if n.is_a? PathMapper::DirNode }.compact.to_set
        containers = (docker & sx)

        { data: containers.to_a }
      end

      def add(name:, mail: 'model', admin_mail: nil, model: nil)
        return { error: :logical_error, message: 'Container already running.' } if @docker_api.container_info(name)
        return { error: :input_error, message: 'No model given.' } if (model_ = model || @config.default_model).empty?

        # config
        config_path_ = "#{@config_path}/containers/#{name}"
        config_path_mapper = PathMapper.new(config_path_)
        FileUtils.mkdir_p config_path_

        # model
        create_conf("#{config_path_}/model", model) unless model.nil?
        model_mapper = @config.models.f(:"#{model_}")

        # image
        return { error: :input_error, message: "No docker_image specified in model #{model_}." } if (image = model_mapper.docker_image).nil?

        # mail
        unless mail != 'no'
          if mail == 'yes'
            create_conf("#{config_path_}/mail", mail)
            admin_mail_ = admin_mail
            create_conf("#{config_path_}/admin_mail", admin_mail_) unless admin_mail_.nil?
            return { error: :input_error, message: 'Admin mail required.' } if admin_mail_.nil?
          elsif mail == 'model'
            if model_mapper.default_mail == 'yes'
              admin_mail_ = admin_mail || model_mapper.default_admin_mail
              return { error: :input_error, message: 'Admin mail required.' } if admin_mail_.nil?
            end
          end
        end

        # lib
        lib_path_ = "#{@lib_path}/containers/#{name}"
        lib_path_mapper = PathMapper.new(lib_path_)
        FileUtils.rm_rf "#{lib_path_}/configs"
        FileUtils.mkdir_p "#{lib_path_}/configs"
        FileUtils.mkdir_p "#{lib_path_}/web"

        # user/group
        self.command("groupadd #{name}")
        self.command("useradd #{name} -g #{name} -d #{lib_path_}/web/")

        user = Etc.getpwnam(name)

        write_if_not_exist("#{lib_path_}/configs/etc-group", "#{name}:x:#{user.gid}:")
        write_if_not_exist("#{lib_path_}/configs/etc-passwd", "#{name}:x:#{user.uid}:#{user.gid}::/web/:")

        # services
        cserv = @config.containers.f(name).services._grep(/.*\.erb/).map {|n| [n._name, n]}.to_h
        mserv = model_mapper.services._grep(/.*\.erb/).map {|n| [n._name, n]}.to_h
        services = mserv.merge!(cserv)

        supervisor_path = "#{lib_path_}/supervisor"
        FileUtils.mkdir_p supervisor_path
        services.each do |_name, node|
          text = erb(node, model: model_, container: config_path_mapper)
          create_conf("#{supervisor_path}/#{_name[/.*[^\.erb]/]}", text)
        end

        # container
        commands = []
        [model_mapper, @config].each do |mapper|
          unless mapper.f('container.rb').nil?
            ex = ScriptExecutor::Container.new(model: model_mapper, configs: config_path_mapper, lib_configs: lib_path_mapper.configs)
            ex.execute(mapper.f('container.rb').to_s)
            commands += ex.commands
          end
        end
        commands.each {|c| self.command c }

        # docker
        write_if_not_exist('/etc/security/docker.conf', "@#{name} #{name}")

        # run container
        self.command "docker run --detach --name #{name} -v #{lib_path_}/configs/:/.configs:ro
                      -v #{lib_path_}/web:/web #{image} /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf".split

        { error: :error, message: 'Unable to run docker container.' } unless @docker_api.container_info(name)
      end

      def delete(name:)
        @docker_api.container_kill(name)
        @docker_api.container_rm(name)
        remove_line_from_file('/etc/security/docker.conf', "@#{name} #{name}")

        begin
          gid = Etc.getgrnam(name).gid

          Etc.passwd do |user|
            self.command("userdel #{user.name}") if user.gid == gid
          end
        rescue ArgumentError => e
          # repeated command execution: group name already does not exist
        end

        FileUtils.rm_rf "#{@lib_path}/containers/#{name}"

        {}
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

      def admin(name:, logger: @logger)
        Admin.new(name: name, logger: logger)
      end
    end
  end
end
