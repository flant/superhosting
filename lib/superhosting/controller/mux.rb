module Superhosting
  module Controller
    class Mux < Base
      attr_writer :index

      def initialize(**kwargs)
        super
        @container_controller = self.get_controller(Container)
      end

      def add(name:)
        if (resp = self.adding_validation(name: name))
          mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).get

          # image
          return { error: :input_error, code: :no_docker_image_specified_in_mux, data: { mux: name } } if (image = mapper.docker.image).nil?

          # docker
          mapper.erb_options = { mux: mapper }
          all_options = mapper.docker.grep_files.map {|n| [n.name[/(.*(?=\.erb))|(.*)/].to_sym, n] }.to_h
          command_options = @docker_api.grab_container_options(command_options: all_options)

          volume_opts = []
          mapper.docker.f('volume', overlay: false).each {|v| volume_opts += v.lines unless v.nil? }
          volume_opts.each {|val| command_options << "--volume #{val}" }

          @container_controller._run_docker(name: name, options: command_options, image: image, command: all_options[:command])
        else
          resp
        end
      end

      def reconfig(name:, configure_only: nil, apply_only: nil)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.reconfig(name: container_name, configure_only: configure_only, apply_only: apply_only)).net_status_ok?
          end
        end
        resp
      end

      def adding_validation(name:)
        if (resp = @container_controller.base_validation(name: name)).net_status_ok?
          resp = self.not_running_validation(name: name)
        end
        resp
      end

      def existing_validation(name:)
        self.index.include?(name) ? self.running_validation(name: name) : { error: :logical_error, code: :mux_does_not_exists, data: { name: name } }
      end

      def not_running_validation(name:)
        @container_controller.not_running_validation(name: name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: name } }
      end

      def running_validation(name:)
        @container_controller.running_validation(name: name).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_not_running, data: { name: name } }
      end

      def index
        @index || self.reindex
      end

      def reindex
        @index ||= {}
        @container_controller.list[:data].each do |container|
          container_name = container[:name]
          next if (container_index = @container_controller.index[container_name]).nil?
          container_mapper = container_index[:mapper]
          if (mux_mapper = container_mapper.mux).file?
            mux_name = mux_mapper.value
            (@index[mux_name] ||= []) << container_name if @container_controller.running_validation(name: container_name).net_status_ok?
          end
        end
        @index
      end

      def index_pop(mux_name, container_name)
        if self.index.key? mux_name
          self.index[mux_name].delete(container_name)
          self.index.delete(mux_name) if self.index[mux_name].empty?
        end
      end

      def index_push(mux_name, container_name)
        self.index[mux_name] ||= []
        self.index[mux_name] << container_name
      end
    end
  end
end