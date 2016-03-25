module Superhosting
  module ConfigExecutor
    class Container < Base
      attr_accessor :container, :mux

      def initialize(container:, registry_mapper:, on_reconfig:, on_config:, mux: nil, **kwargs)
        self.container = container
        self.mux = mux
        @registry_mapper = registry_mapper
        @on_config = on_config
        @on_reconfig = on_reconfig
        super(**kwargs)
      end

      def mkdir(path)
        if @on_config
          PathMapper.new(path).create!
          @registry_mapper.append!(path)
        end
      end

      def config(save_to, script=nil, **options)
        if @on_config
          save_to_mapper = PathMapper.new(save_to)
          script = options.delete(:source) || save_to_mapper.name if script.nil?
          script = script.end_with?('.erb') ? script : "#{script}.erb"
          raise NetStatus::Exception.new(error: :error, code: :can_not_pass_an_absolute_path, data: { path: script }) if Pathname.new(script).absolute?
          script_mapper = self.config_mapper(options).config_templates.f(script)
          raise NetStatus::Exception.new(error: :error, code: :file_does_not_exists, data: { path: script_mapper.path.to_s }) if script_mapper.nil?
          save_to_mapper.put!(script_mapper)
          @registry_mapper.append!(save_to_mapper.path)
        end
      end

      def on_reconfig(cmd)
        self.commands << cmd if @on_reconfig
      end

      def run_commands
        self.commands.each do |cmd|
          if cmd == :container_restart
            self.docker_api.container_restart!(self.container.name)
          else
            self.command! cmd
          end
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