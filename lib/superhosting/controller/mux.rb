module Superhosting
  module Controller
    class Mux < Base
      def add(name:)
        if (resp = adding_validation(name: name))
          mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).inheritors_mapper

          # docker
          mapper.erb_options = { mux: mapper }
          if (resp = @container_controller._collect_docker_options(mapper: mapper, model_or_mux: name)).net_status_ok?
            docker_options = resp[:data]
            @lib.muxs.f(name).docker_options.put!(Marshal.dump(docker_options), logger: false)
            @container_controller._safe_run_docker(*docker_options, name: _container_name(name: name)).net_status_ok!
          end
        else
          resp
        end
      end

      def _delete(name:)
        @lib.muxs.f(name).delete!
        @container_controller._delete_docker(name: _container_name(name: name))
      end

      def reconfigure(name:)
        if (resp = useable_validation(name: name)).net_status_ok?
          index[name].each do |container_name|
            break unless (resp = @container_controller.reconfigure(name: container_name)).net_status_ok?
          end
        end
        resp
      end

      def update(name:)
        if (resp = useable_validation(name: name)).net_status_ok?
          mux_mapper = @container_controller.index[index[name].first][:mux_mapper]
          docker_options = @lib.muxs.f(name).docker_options.value
          @container_controller._update(name: _container_name(name: name), docker_options: Marshal.load(docker_options))
          @docker_api.image_pull(mux_mapper.container.docker.image.value)
          index[name].each do |container_name|
            docker_options = Marshal.load(@container_controller.index[container_name][:mapper].lib.docker_options.value)
            @container_controller._update(name: container_name, docker_options: docker_options, with_pull: false)
          end
        end
        resp
      end

      def tree(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = @config.muxs.f(name)
          { data: MapperInheritance::Mux.new(mapper).collect_inheritors_tree(mux: true)[name] }
        else
          resp
        end
      end

      def inspect(name:, inheritance: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).inheritors_mapper
          if inheritance
            data = separate_inheritance(mapper) do |mapper, inheritors|
              ([mapper] + inheritors).inject([]) do |inheritance, m|
                inheritance << { 'name' => mapper_name(m), 'options' => get_mapper_options(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: { 'name' => mapper.name, 'options' => get_mapper_options(mapper, erb: true) } }
          end
        else
          resp
        end
      end

      def options(name:, inheritance: false)
        if (resp = existing_validation(name: name)).net_status_ok?
          mapper = MapperInheritance::Mux.new(@config.muxs.f(name)).inheritors_mapper
          if inheritance
            data = separate_inheritance(mapper) do |mapper, inheritors|
              ([mapper] + inheritors).inject([]) do |inheritance, m|
                inheritance << { mapper_name(m) => get_mapper_options_pathes(m, erb: true) }
              end
            end
            { data: data }
          else
            { data: get_mapper_options_pathes(mapper, erb: true) }
          end
        else
          resp
        end
      end

      def inheritance(name:)
        if (resp = existing_validation(name: name)).net_status_ok?
          inheritance = MapperInheritance::Mux.new(@config.muxs.f(name)).inheritors_mapper
          { data: inheritance.map { |m| { 'type' => mapper_type(m.parent), 'name' => mapper_name(m) } } }
        else
          resp
        end
      end

      def _container_name(name:)
        "mux-#{name}"
      end
    end
  end
end
