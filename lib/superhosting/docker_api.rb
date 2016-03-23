module Superhosting
  class DockerApi
    include Helper::Cmd
    include Helper::Logger

    AVAILABLE_DOCKER_OPTIONS = [:user, :cpu_period, :cpu_quota, :cpu_shares, :memory, :memory_swap]

    def initialize(**kwargs)
      @socket = kwargs[:socket] || '/var/run/docker.sock'
    end

    def raw_connection
      Excon.new('unix:///', socket: @socket)
    end

    def resp_if_success(resp)
      JSON.load(resp.body) if resp.status == 200
    end

    def container_info(name)
      resp_if_success raw_connection.request(method: :get, path: "/containers/#{name}/json")
    end

    def container_list
      resp_if_success raw_connection.request(method: :get, path: '/containers/json')
    end

    def container_kill!(name)
      resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/kill")
      self.debug(desc: { code: :container_kill, data: { name: name } })
    end

    def container_rm!(name)
      resp_if_success raw_connection.request(method: :delete, path: "/containers/#{name}")
      self.debug(desc: { code: :container_remove, data: { name: name } })
    end

    def container_stop!(name)
      resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/stop")
      self.debug(desc: { code: :container_stop, data: { name: name } })
    end

    def container_rm_inactive!(name)
      self.container_rm!(name) if self.container_exists?(name) and !self.container_running?(name)
    end

    def container_not_running?(name)
      !container_running?(name)
    end

    def container_running?(name)
      resp = container_info(name)
      resp.nil? ? false : resp['State']['Status'] == 'running'
    end

    def container_not_exists?(name)
      !container_exists?(name)
    end

    def container_exists?(name)
      container_info(name).nil? ? false : true
    end

    def container_run(name, options, image, command)
      cmd = "docker run --detach --name #{name} #{options.join(' ')} #{image} #{command}"
      self.command!(cmd, desc: { code: :container_add, data: { name: name } }) # TODO
    end

    def grab_container_options(command_options)
      options = []
      AVAILABLE_DOCKER_OPTIONS.map do |k|
        unless (value = command_options[k]).nil?
          value.lines.each {|val| options << "--#{k.to_s.sub('_', '-')} #{val}" }
        end
      end
      options
    end
  end
end
