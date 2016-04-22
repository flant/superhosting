module Superhosting
  module ConfigExecutor
    class Container < Base
      attr_accessor :container, :mux, :mux_name, :registry_files

      def initialize(container:, on_reconfig:, on_config:, mux: nil, **kwargs)
        self.container = container
        self.mux = mux
        self.mux_name = mux.nil? ? mux : "mux-#{mux.name}"
        self.registry_files = []
        @on_config = on_config
        @on_reconfig = on_reconfig
        super(**kwargs)
      end

      def mkdir(path, **options)
        return unless @on_config
        PathMapper.new(path).create!
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
                container = case in_option
                              when :container then
                                container.name
                              when :mux then
                                mux_name
                              else
                                raise NetStatus::Exception, error: :error, code: :on_reconfig_not_supported_option_value, data: { value: in_option, option: 'in' }
                            end

                "docker exec #{container} #{cmd}"
              else
                cmd
              end

        commands << cmd
      end

      def run_commands
        commands.each do |cmd|
          if cmd == :container_restart
            container.lib.signature.delete!(logger: false)
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

      def base_mapper
        container
      end

      def config_mapper(options)
        base_mapper.erb_options = instance_variables_to_hash(self).merge(options)
        base_mapper
      end
    end
  end
end
