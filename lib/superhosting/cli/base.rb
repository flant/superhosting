module Superhosting
  module Cli
    module Cmd; end
    class Base
      include Mixlib::CLI

      COMMANDS_MODULE = Cmd
      CONTROLLERS_MODULE = Superhosting::Controller
      CONTROLLER_BASE_OPTIONS = [:config_path, :lib_path]

      banner "#{?# * 50}\n#{?# * 24}SX#{?# * 24}\n#{?# * 50}\n\n"

      option :help,
             :short        => '-h',
             :long         => '--help',
             :on           => :tail

      option :debug,
             :long         => '--debug',
             :boolean      => true,
             :on           => :tail

      option :config_path,
             :long         => '--config-path PATH',
             :on           => :tail

      option :lib_path,
             :long         => '--lib-path PATH',
             :on           => :tail

      def initialize(argv, node)
        self.class.options.merge!(Base::options)
        super()

        @pos_args = parse_options(argv)
        @node = node

        @logger = Logger.new(STDOUT)
        @logger.level = config[:debug] ? Logger::DEBUG : Logger::INFO
        @logger.formatter = proc {|severity, datetime, progname, msg| sprintf("%s\n", msg.to_s.strip) }

        if config[:help] or self.class == Base
          self.help
          exit 1
        end
      end

      def help
        def get_childs_banners(node)
          if node.is_a? Hash
            node.map do |k,v|
              if v.is_a? Hash
                get_childs_banners(node[k])
              else
                v.banner
              end
            end.join("\n")
          else
            node.banner
          end
        end

        @logger.info("#{opt_parser.to_s}\n#{get_childs_banners(@node) if self.class == Base}")
      end

      def run
        def get_subcontroller_option
          key = :"#{self.class.get_split_class_name[-2]}_name"
          config[key] if config.key? key
        end

        method = get_controller

        opts = {}
        method.parameters.each do |req, name|
          if req.to_s.start_with? 'key'
            opt = config[name]
            raise Errors::Base.new('You must supply required parameter') unless opt = get_subcontroller_option || @pos_args.shift if name == :name
            opts.merge!(name => opt)
          end
        end
        method.call(**opts)
      end

      def get_controller
        node = CONTROLLERS_MODULE
        names = self.class.get_split_class_name

        names.each do |n|
          c_name = n.capitalize.to_sym
          m_name = n.to_sym

          if node.respond_to? :constants and node.constants.include? c_name
            node = node.const_get(c_name)
          elsif node.respond_to? :instance_methods and node.instance_methods(false).include? m_name
            params = node.instance_method(:initialize).parameters

            opts = {}
            params.each do |req, name|
              if req.to_s.start_with? 'key'
                if name == :name
                  raise Errors::Base.new('You must supply required parameter') unless opt = @pos_args.shift
                elsif config.key? :name
                  opt = config[:name]
                end
                opts.merge!(name => opt) unless opt.nil?
              end
            end

            CONTROLLER_BASE_OPTIONS.each {|opt| opts.merge!(opt => config[opt]) unless config[opt].nil? }
            opts.merge!(logger: @logger)
            return node.new(**opts).method(m_name)
          end
        end
        raise Errors::Base.new('Method doesn\'t found')
      end

      class << self
        def start(args)
          def clear_args(args, cmd)
            split_toggle_case_name(cmd).length.times{ args.shift }
            args
          end

          prepend
          cmd, node = get_cmd_and_node(args)
          args = clear_args(args, cmd)
          cmd.new(args, node).run
        end

        def prepend
          set_commands_hierarchy
          set_banners
        end

        def set_banners(node=@@commands_hierarchy, path=[])
          node.each do |k,v|
            path_ = path.dup
            path_ << k
            if v.is_a? Hash
              set_banners(v, path_)
            else
              v.banner("sx #{path_.join(' ')}#{' <param>' if v.has_required_param?}#{' (options)' unless v.options.empty?}")
            end
          end
        end

        def has_required_param?
          false
        end

        def set_commands_hierarchy
          def get_commands
            COMMANDS_MODULE.constants.select {|c| Class === COMMANDS_MODULE.const_get(c) }.sort
          end

          @@commands_hierarchy = get_commands.inject({}) do |h,k|
            node = h
            parts = split_toggle_case_name(k)
            parts.each do |cmd|
              node = (node[cmd] ||= (cmd == parts.last) ? COMMANDS_MODULE.const_get(k) : {})
            end
            h
          end
        end

        def get_split_class_name
          self.split_toggle_case_name(self.name.split('::').last)
        end

        def split_toggle_case_name(klass)
          klass.to_s.gsub(/([[:lower:]])([[:upper:]])/, '\1 \2').split(' ').map(&:downcase)
        end

        def get_cmd_and_node(args)
          def positional_arguments(args)
            args.select { |arg| arg =~ /^([[:alnum:]\_\-]+)$/ }
          end

          args = positional_arguments(args)
          node = @@commands_hierarchy
          path = []
          key = ''
          cmd = nil
          while arg = args.shift and cmd.nil?
            res = node.keys.select { |k| k.start_with? arg }

            case res.count
              when 1
                key = res.first
                cmd = node[key] if node[key].is_a? Class
              when 0
                break
              else
                raise Errors::AmbiguousCommand.new(path: path, commands: res)
            end

            path << key
            node = node[key]
          end

          cmd ||= self
          node = { key => node }

          [cmd, node]
        end
      end
    end
  end
end
