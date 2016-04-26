module Superhosting
  module Controller
    class Container
      def _delete_docker(name:)
        if @docker_api.container_exists?(name)
          @docker_api.container_unpause!(name) if @docker_api.container_paused?(name)
          @docker_api.container_kill!(name)
          @docker_api.container_rm!(name)
        end
      end

      def _recreate_docker(*docker_options, name:)
        docker_options ||= _collect_docker_options(mapper: index[name][:mapper]).net_status_ok!
        _delete_docker(name: name)
        _run_docker(*docker_options, name: name)
      end

      def _run_docker(*docker_options, name:)
        docker_options = _collect_docker_options(mapper: index[name][:mapper]).net_status_ok![:data] if docker_options.empty?
        @docker_api.container_run(name, *docker_options)
      end

      def _safe_run_docker(*docker_options, name:, restart: false)
        if restart
          _recreate_docker(*docker_options, name: name)
        elsif @docker_api.container_running?(name)
        elsif @docker_api.container_exists?(name)
          if @docker_api.container_exited?(name)
            @docker_api.container_start!(name)
          elsif @docker_api.container_paused?(name)
            @docker_api.container_unpause!(name)
          elsif @docker_api.container_restarting?(name)
            Polling.start 10 do
              break unless @docker_api.container_restarting?(name)
              sleep 2
            end
          else
            _recreate_docker(*docker_options, name: name)
          end
        else
          _run_docker(*docker_options, name: name)
        end
        running_validation(name: name)
      end

      def _collect_docker_options(mapper:, model_or_mux: nil)
        model_or_mux ||= mapper.f('model', default: @config.default_model)
        return { error: :input_error, code: :no_docker_image_specified_in_model_or_mux, data: { name: model_or_mux } } if (image = mapper.docker.image).nil?

        all_options = mapper.docker.grep_files.map { |n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n.value] }.to_h
        return { error: :logical_error, code: :docker_command_not_found } if (command = all_options[:command]).nil?

        command_options = @docker_api.grab_container_options(all_options)
        volume_opts = []
        mapper.docker.f('volume', overlay: false).each { |v| volume_opts += v.lines unless v.nil? }
        volume_opts.each { |val| command_options << "--volume #{val}" }

        { data: [command_options, image.value, command] }
      end

      def _lib_docker_options(lib_mapper:)
        lib_mapper.docker_options.tap do |docker_options|
          { error: :logical_error, code: :no_docker_options_specified_in_container_or_mux, data: { name: mapper_name(lib_mapper) } }.net_status_ok! if docker_options.nil?
        end.value
      end
    end
  end
end
