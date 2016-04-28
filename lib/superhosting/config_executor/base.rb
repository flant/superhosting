module Superhosting
  module ConfigExecutor
    class Base
      include Helpers

      attr_accessor :commands
      attr_accessor :lib, :etc, :docker_api, :registry_files

      def initialize(on_reconfig:, on_config:, lib:, etc:, docker_api:, **kwargs)
        kwargs.each do |k, v|
          instance_variable_set("@#{k}", v)
          self.class.class_eval("attr_accessor :#{k}")
        end

        self.commands = []
        self.lib = lib
        self.etc = etc
        self.docker_api = docker_api

        @on_config = on_config
        @on_reconfig = on_reconfig

        self.registry_files = []
      end

      def execute(script)
        instance_eval(script, script.path.to_s)
      end

      def mkdir(path, **options)
        return unless @on_config
        PathMapper.new(path).create!
        set_file_attributes(path, options)
        registry_files << path.to_s
      end

      def touch(path, **options)
        return unless @on_config
        touch!(path)
        set_file_attributes(path, options)
        registry_files << path.to_s
      end

      def config(save_to, script = nil, **options)
        return unless @on_config
        save_to_mapper = PathMapper.new(save_to)
        script = options.delete(:source) || save_to_mapper.name if script.nil?
        script = script.to_s.end_with?('.erb') ? script : "#{script}.erb"
        raise NetStatus::Exception, error: :error, code: :can_not_pass_an_absolute_path, data: { path: script } if Pathname.new(script).absolute?
        script_mapper = config_mapper(options).config_templates.f(script)
        raise NetStatus::Exception, error: :error, code: :file_does_not_exists, data: { path: script_mapper.path.to_s } if script_mapper.nil?
        save_to_mapper.put!(script_mapper)
        set_file_attributes(save_to_mapper.path, options)
        registry_files << save_to_mapper.path.to_s
      end

      def on_reconfig(cmd, **kwargs)
        return unless @on_config
        in_option = kwargs[:in]
        cmd = if in_option
                container_name = case in_option
                                   when :container then
                                     container.container_name
                                   when :mux then
                                     mux.container_name
                                   else
                                     raise NetStatus::Exception, error: :error, code: :on_reconfig_not_supported_option_value, data: { value: in_option, option: 'in' }
                                 end

                "docker exec #{container_name} #{cmd}"
              else
                cmd
              end

        commands << cmd
      end

      def run_commands
        commands.each do |cmd|
          if cmd == :container_restart
            base_mapper.lib.signature.delete!(logger: false)
          else
            command! cmd
          end
        end
      end

      protected

      def set_file_attributes(path, user: nil, group: nil, mode: nil, **_kwargs)
        chown!(user, group, path) if user && group
        chmod!(mode, path) if mode
      end

      def config_mapper(options)
        base_mapper.erb_options = instance_variables_to_hash(self).merge(options)
        base_mapper
      end
    end
  end
end
