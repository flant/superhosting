require 'excon'
require 'json'

module Superhosting
  class DockerApi
    def initialize(**kwargs)
      @socket = kwargs[:socket] || '/var/run/docker.sock'
    end

    def raw_connection
      Excon.new('unix:///', socket: @socket)
    end

    def container_info(name)
      resp = raw_connection.request(method: :get, path: "/containers/#{name}/json")
      JSON.load(resp.body) if resp.status == 200
    end
  end
end
