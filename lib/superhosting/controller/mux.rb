module Superhosting
  module Controller
    class Mux < Base
      def initialize(**kwargs)
        @container_controller = self.get_controller(Container)
      end

      def add(name:)
        if (resp = self.not_running_validation(name: name))
          mux_mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).get

          # image
          return { error: :input_error, code: :no_docker_image_specified_in_mux, data: { mux: name } } if (image = mux_mapper.docker.image).nil?

          # docker
          mux_mapper.erb_options = { mux: mux_mapper }
          all_options = mux_mapper.docker.grep_files.map {|n| [n.name[/.*[^\.erb]/].to_sym, n] }.to_h
          command_options = container_controller._grab_options(command_options: all_options)
          @container_controller._run_docker(name: name, command_options: command_options, image: image)
        else
          resp
        end
      end

      def not_running_validation(name:)
        @container_controller.not_running_validation(name: name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: name } }
      end
    end
  end
end