module Superhosting
  module ScriptExecutor
    class Container < Base
      attr_accessor :commands
      attr_accessor :model, :configs, :lib_configs

      def initialize(**kwargs)
        self.commands = []
        self.model = kwargs.delete(:model)
        self.configs = kwargs.delete(:configs)
        self.lib_configs = kwargs.delete(:lib_configs)
        super
      end

      def config(save_to, script, **options)
        script = [self.configs.f(script)._path, self.model.f(script)._path].find {|f| File.exists? f }
        raise NetStatus::Exception.new(error: :error, message: "File does not exist") if script.nil?
        script = File.read(script)
        opts = instance_variables_to_hash.merge(options)
        File.open(save_to, 'w') {|f| f.write(self.class.new(**opts).execute(script)) }
      end

      def container_config(save_to, script, **options)
        raise NetStatus::Exception.new(error: :error, message: "File '#{save_to}' has incorrect name format") if save_to.include? File::SEPARATOR
        config(File.join(self.lib_configs._path, save_to), script, options)
      end

      def on_reconfig(cmd)
        self.commands << cmd
      end
    end
  end
end