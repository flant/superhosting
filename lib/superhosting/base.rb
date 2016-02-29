module Superhosting
  class Base
    def initialize(config_path: '/etc/sx', lib_path: '/var/lib/sx', logger: nil, docker_socket: nil)
      @config_path = Pathname.new(config_path)
      @lib_path = Pathname.new(lib_path)
      @config = PathMapper::Mapper.new(config_path)
      @lib = PathMapper::Mapper.new(lib_path)
      @logger = logger

      @docker_api = DockerApi.new(socket: docker_socket)
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
    end

    def command!(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      if cmd.status.success?
        debug([cmd.stdout, cmd.stderr].join("\n"))
        cmd
      else
        raise NetStatus::Exception.new(error: :error, message: [cmd.stdout, cmd.stderr].join("\n"))
      end
    end

    def command(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      debug([cmd.stdout, cmd.stderr].join("\n"))
      cmd
    end

    def create_conf(path, conf)
      File.open(path, 'w') {|f| f.write(conf) }
    end

    def write_if_not_exist(path, line)
       File.open(path, 'a+') do |f|
         f.puts(line) unless f.each_line.any? { |l| l =~ Regexp.new(line) }
       end
    end

    def remove_line_from_file(path, line)
      lines = File.readlines(path).select {|l| l !~ Regexp.new(line) }
      File.open(path, 'w') {|f| f.write lines.join('') }
    end

    def erb(template, vars)
      ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
    rescue Exception => e
      raise NetStatus::Exception, e.net_status
    end
  end
end