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
      self.debug_operation(desc: { code: :container, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          self.storage[name] = :not_running if dry_run
          resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/kill") unless dry_run
        end
        blk.call(code: :killed)
      end
    end

    def container_rm!(name)
      self.debug_operation(desc: { code: :container, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          self.storage.delete(name) if dry_run
          resp_if_success raw_connection.request(method: :delete, path: "/containers/#{name}") unless dry_run
        end
        blk.call(code: :removed)
      end
    end

    def container_stop!(name)
      self.debug_operation(desc: { code: :container, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          self.storage[name] = :not_running if dry_run
          resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/stop") unless dry_run
        end
        blk.call(code: :stopped)
      end
    end

    def container_restart!(name)
      self.debug_operation(desc: { code: :container, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/restart") unless dry_run
        end
        blk.call(code: :restarted)
      end
    end

    def container_rm_inactive!(name)
      self.container_rm!(name) if self.container_exists?(name) and !self.container_running?(name)
    end

    def container_not_running?(name)
      self.with_dry_run do |dry_run|
        return true if dry_run and self.storage[name] == :not_running
        !container_running?(name)
      end
    end

    def container_running?(name)
      self.with_dry_run do |dry_run|
        return true if dry_run and self.storage[name] == :running
        resp = container_info(name)
        resp.nil? ? false : resp['State']['Status'] == 'running'
      end
    end

    def container_not_exists?(name)
      !container_exists?(name)
    end

    def container_exists?(name)
      self.with_dry_run do |dry_run|
        return true if dry_run and self.storage.key? name
        container_info(name).nil? ? false : true
      end
    end

    def container_run(name, options, image, command)
      cmd = "docker run --detach --name #{name} #{options.join(' ')} #{image} #{command}"
      self.debug_operation(desc: { code: :container, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          self.storage[name] = :running if dry_run
        end

        self.command!(cmd).tap do
          blk.call(code: :added)
        end
      end
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
