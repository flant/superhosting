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
          mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).set_inheritors

          # docker
          mapper.erb_options = { mux: mapper }
          if (resp = @container_controller._collect_docker_options(mapper: mapper, model_or_mux: name)).net_status_ok?
            docker_options = resp[:data]
            @lib.muxs.f(name).docker_options.put!(Marshal.dump(docker_options))
            @container_controller._safe_run_docker(*docker_options, name: self._container_name(name: name) ).net_status_ok!
          end
        else
          resp
        end
      end

      def _delete(name:)
        @lib.muxs.f(name).delete!
        @container_controller._delete_docker(name: self._container_name(name: name))
      end

      def reconfigure(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          self.index[name].each do |container_name|
            break unless (resp = @container_controller.reconfigure(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          mux_mapper = @container_controller.index[self.index[name].first][:mux_mapper]
          docker_options = @lib.muxs.f(name).docker_options.value
          @container_controller._update(name: self._container_name(name: name), docker_options: Marshal.load(docker_options))
          @docker_api.image_pull(mux_mapper.container.docker.image.value)
          self.index[name].each do |container_name|
            docker_options = Marshal.load(@container_controller.index[container_name][:mapper].lib.docker_options.value)
            @container_controller._update(name: container_name, docker_options: docker_options, with_pull: false)
          end
        end
        resp
      end

      def _container_name(name:)
        "mux-#{name}"
      end

      def adding_validation(name:)
        if (resp = @container_controller.base_validation(name: name)).net_status_ok?
          resp = self.not_running_validation(name: self._container_name(name: name))
        end
        resp
      end

      def existing_validation(name:)
        self.index.include?(name) ? {} : { error: :logical_error, code: :mux_does_not_exists, data: { name: name } }
      end

      def not_running_validation(name:)
        @container_controller.not_running_validation(name: self._container_name(name: name)).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_running, data: { name: name } }
      end

      def running_validation(name:)
        @container_controller.running_validation(name: self._container_name(name: name)).net_status_ok? ? {} : { error: :logical_error, code: :mux_is_not_running, data: { name: name } }
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @@index ||= {}
        @container_controller._list.map do |container_name, data|
          container_mapper = @container_controller.index[container_name][:mapper]
          if (mux_mapper = container_mapper.mux).file?
            mux_name = mux_mapper.value
            if @container_controller.running_validation(name: container_name).net_status_ok?
              self.index_push(mux_name, container_name)
            else
              self.index_pop(mux_name, container_name)
            end
          end
        end
        @@index
      end

      def index_pop(mux_name, container_name)
        if self.index.key? mux_name
          self.index[mux_name].delete(container_name)
          self.index.delete(mux_name) if self.index[mux_name].empty?
        end
      end

      def index_push(mux_name, container_name)
        self.index[mux_name] ||= []
        self.index[mux_name] << container_name unless self.index[mux_name].include? container_name
      end
    end
  end
end