module Superhosting
  class DockerApi
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

    def container_kill(name)
      resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/kill")
    end

    def container_rm(name)
      resp_if_success raw_connection.request(method: :delete, path: "/containers/#{name}")
    end

    def container_list
      resp_if_success raw_connection.request(method: :get, path: '/containers/json')
    end
  end
end
