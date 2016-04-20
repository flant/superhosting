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

    def image_info(name)
      resp_if_success raw_connection.request(method: :get, path: "/images/#{name}/json")
    end

    def base_action(name, code)
      self.debug_operation(desc: { code: code, data: { name: name } }) do |&blk|
        self.with_dry_run do |dry_run|
          yield blk, dry_run
        end
      end
    end

    def image_pull(name)
      cmd = "docker pull #{name}"
      base_action(name, :image_pull) do |blk, dry_run|
        begin
          self.command!(cmd, logger: false) unless dry_run
          blk.call(code: :pulled)
        rescue NetStatus::Exception => e
          blk.call(code: :not_found)
        end
      end
    end

    def container_info(name)
      resp_if_success raw_connection.request(method: :get, path: "/containers/#{name}/json")
    end

    def container_list
      resp_if_success raw_connection.request(method: :get, path: '/containers/json')
    end

    def container_kill!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage.delete(name) if dry_run
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/kill") unless dry_run
        blk.call(code: :killed)
      end
    end

    def container_rm!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage.delete(name) if dry_run
        resp_if_success raw_connection.request(method: :delete, path: "/containers/#{name}") unless dry_run
        blk.call(code: :removed)
      end
    end

    def container_stop!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage[name] = 'exited' if dry_run
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/stop") unless dry_run
        blk.call(code: :stopped)
      end
    end

    def container_start!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage[name] = 'running' if dry_run
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/start") unless dry_run
        blk.call(code: :started)
      end
    end

    def container_pause!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage[name] = 'paused' if dry_run
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/pause") unless dry_run
        blk.call(code: :paused)
      end
    end

    def container_unpause!(name)
      base_action(name, :container) do |blk, dry_run|
        self.storage[name] = 'running' if dry_run
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/unpause") unless dry_run
        blk.call(code: :unpaused)
      end
    end

    def container_restart!(name)
      base_action(name, :container) do |blk, dry_run|
        resp_if_success raw_connection.request(method: :post, path: "/containers/#{name}/restart") unless dry_run
        self.storage[name] = 'running' if dry_run
        blk.call(code: :restarted)
      end
    end

    def container_rm_inactive!(name)
      self.container_rm!(name) if self.container_exists?(name) and !self.container_running?(name)
    end

    def container_status?(name, status)
      self.with_dry_run do |blk, dry_run|
        return true if dry_run and self.storage[name] == status
        resp = container_info(name)
        if resp.nil?
          false
        else
          resp['State'][status.capitalize]
        end
      end
    end

    def container_running?(name)
      self.with_dry_run do |blk, dry_run|
        return true if dry_run and self.storage[name] == 'running'
        resp = container_info(name)
        if resp.nil?
          false
        else
          resp['State']['Running'] and %w(Restarting Paused OOMKilled Dead).all? {|c| !resp['State'][c] }
        end
      end
    end

    def container_not_running?(name)
      !container_running?(name)
    end

    def container_restarting?(name)
      container_status?(name, 'restarting')
    end

    def container_paused?(name)
      container_status?(name, 'paused')
    end

    def container_exited?(name)
      container_status?(name, 'exited')
    end

    def container_dead?(name)
      container_status?(name, 'dead')
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

    def container_image?(name, image)
      container = container_info(name)
      image = image_info(image)

      if container.nil? or image.nil?
        false
      else
        container['Image'] == image['Id']
      end
    end

    def container_run(name, options, image, command)
      cmd = "docker run --detach --name #{name} #{options.join(' ')} #{image} #{command}"
      base_action(name, :container) do |blk, dry_run|
        self.storage[name] = 'running' if dry_run
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
