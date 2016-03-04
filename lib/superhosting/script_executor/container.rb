module Superhosting
  module ScriptExecutor
    class Container < Base
      attr_accessor :container, :container_name, :container_lib, :registry_path, :on_reconfig_only

      def initialize(container:, container_name:, container_lib:, registry_path:, on_reconfig_only: false, **kwargs)
        self.container = container
        self.container_name = container_name
        self.container_lib = container_lib
        self.registry_path = registry_path
        self.on_reconfig_only = on_reconfig_only
        super(**kwargs)
      end

      def config(save_to, script, **options)
        unless self.on_reconfig_only
          script_mapper = self.container.f(script, default: self.model.f(script))
          raise NetStatus::Exception.new(error: :error, message: 'File does not exist') if script_mapper.nil?
          opts = instance_variables_to_hash(self).merge(options)
          FileUtils.mkdir_p File.dirname(save_to)
          File.open(save_to, 'w') {|f| f.write(erb(script_mapper, **opts)) }
          file_write(self.registry_path, save_to)
        end
      end

      # def container_config(save_to, script, **options)
      #   raise NetStatus::Exception.new(error: :error, message: "File '#{save_to}' has incorrect name format") if save_to.include? File::SEPARATOR
      #   config(File.join(self.lib_configs._path, save_to), script, options)
      # end

      def on_reconfig(cmd)
        self.commands << cmd
      end
    end
  end
end