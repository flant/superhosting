module Superhosting
  module Controller
    class Mux < Base
      attr_writer :mux_index

      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def add(name:)
        if (resp = self.adding_validation(name: name))
          mux_mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).get

          # image
          return { error: :input_error, code: :no_docker_image_specified_in_mux, data: { mux: name } } if (image = mux_mapper.docker.image).nil?

          # docker
          mux_mapper.erb_options = { mux: mux_mapper }
          all_options = mux_mapper.docker.grep_files.map {|n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n] }.to_h
          command_options = @docker_api.grab_container_options(command_options: all_options)

          volume_opts = []
          mux_mapper.docker.f('volume', overlay: false).each {|v| volume_opts += v.lines unless v.nil? }
          volume_opts.each {|val| command_options << "--volume #{val}" }

          @container_controller._run_docker(name: name, options: command_options, image: image, command: all_options[:command])
        else
          resp
        end
      end

      def reconfig(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.mux_index[name].each {|container_name| @container_controller._reconfig(container_name) }
        else
          resp
        end
      end

      def adding_validation(name:)
        if (resp = @container_controller.base_validation(name: name)).net_status_ok?
          resp = self.not_running_validation(name: name)
        end
        resp
      end

      def existing_validation(name:)
        self.mux_index.include?(name) ? self.running_validation(name: name) : { error: :logical_error, code: :mux_does_not_exists, data: { name: name } }
      end

      def not_running_validation(name:)
        @container_controller.not_running_validation(name: name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: name } }
      end

      def running_validation(name:)
        @container_controller.running_validation(name: name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_not_running, data: { name: name } }
      end

      def mux_index
        def generate
          @mux_index = {}
          @container_controller.list[:data].each do |container_name|
            container_mapper = @config.containers.f(container_name)
            model = container_mapper.f('model', default: @config.default_model)
            model_mapper = @config.models.f(model)
            container_mapper = MapperInheritance::Model.new(container_mapper, model_mapper).get
            if (mux_mapper = container_mapper.mux).file?
              mux_name = mux_mapper.value
              (@mux_index[mux_name] ||= []) << container_name
            end
          end

          @mux_index
        end

        @mux_index || generate
      end

      def mux_index_pop(mux_name, container_name)
        if self.mux_index.key? mux_name
          self.mux_index[mux_name].delete(container_name)
          self.mux_index.delete(mux_name) if self.mux_index[mux_name].empty?
        end
      end

      def mux_index_push(mux_name, container_name)
        self.mux_index[mux_name] ||= []
        self.mux_index[mux_name] << container_name
      end
    end
  end
end