module Superhosting
  module ScriptExecutor
    class Container < Base
      attr_accessor :container_name, :container, :registry_mapper, :mux, :on_reconfig_only

      def initialize(container_name:, container:, container_lib:, container_web:, registry_mapper:, mux: nil, on_reconfig_only: false, **kwargs)
        self.container_name = container_name
        self.container = ConfigMapper::Container.new(etc_mapper: container, lib_mapper: container_lib, web_mapper: container_web)
        self.mux = mux
        self.registry_mapper = registry_mapper
        self.on_reconfig_only = on_reconfig_only
        super(**kwargs)
      end

      def mkdir(arg)
        self.commands << "mkdir -p #{arg}"
      end

      def config(save_to, script=nil, **options)
        unless self.on_reconfig_only
          save_to_mapper = PathMapper.new(save_to)
          script = options.delete(:source) || save_to_mapper.name if script.nil?
          script = script.end_with?('.erb') ? script : "#{script}.erb"
          raise NetStatus::Exception.new(error: :error, code: :can_not_pass_an_absolute_path, data: { path: script }) if Pathname.new(script).absolute?
          script_mapper = self.config_mapper(options).config_templates.f(script)
          raise NetStatus::Exception.new(error: :error, code: :file_does_not_exists, data: { path: script_mapper.path.to_s }) if script_mapper.nil?
          save_to_mapper.put!(script_mapper)
          self.registry_mapper.append!(save_to_mapper.path)
        end
      end

      # def container_config(save_to, script, **options)
      #   raise NetStatus::Exception.new(error: :error, message: "File '#{save_to}' has incorrect name format") if save_to.include? File::SEPARATOR
      #   config(File.join(self.lib_configs.path, save_to), script, options)
      # end

      def on_reconfig(cmd)
        if cmd == :container_restart
          self.commands << "docker restart #{self.container_name}" if self.docker_api.container_exists? self.container_name
        else
          self.commands << cmd
        end
      end

      protected

      def base_mapper
        self.container
      end

      def config_mapper(options)
        self.base_mapper.erb_options = instance_variables_to_hash(self).merge(options)
        self.base_mapper
      end
    end
  end
end