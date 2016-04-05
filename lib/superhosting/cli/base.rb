module Superhosting
  module Cli
    module Cmd; end
    class Base
      include Mixlib::CLI
      extend Helper::I18n

      COMMANDS_MODULE = Cmd
      CONTROLLERS_MODULE = Superhosting::Controller
      CONTROLLER_BASE_OPTIONS = [:dry_run, :debug]

      banner "#{?= * 50}\n#{?- * 19}SUPERHOSTING#{?- * 19}\n#{?= * 50}\n\n"

      option :help,
             :short        => '-h',
             :long         => '--help',
             :on           => :tail

      option :debug,
             :long         => '--debug',
             :boolean      => true,
             :on           => :tail

      option :verbose,
             :long         => '--verbose',
             :boolean      => true,
             :on           => :tail

      option :dry_run,
             :long         => '--dry-run',
             :boolean      => true,
             :on           => :tail

      def initialize(argv, node)
        self.class.options.merge!(Base::options)
        super()

        begin
          @pos_args = parse_options(argv)
        rescue OptionParser::InvalidOption => e
          raise NetStatus::Exception, error: :input_error, code: :invalid_cli_option, data: { message: e.message }
        end

        @node = node

        @logger = Logger.new(STDOUT)
        @logger.level = (config[:debug] or config[:dry_run] or config[:verbose]) ? Logger::DEBUG : Logger::INFO
        @logger.formatter = proc {|severity, datetime, progname, msg| sprintf("%s\n", msg.to_s) }

        self.help if config[:help] or self.class == Base
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

        exit 1
      end

      def run
        begin
          net_status = action
          net_status ||= {}

          raise Error::Controller, net_status unless net_status[:error].nil?
          @logger.info(net_status[:data]) unless net_status[:data].nil?
          @logger.debug('Done!')
        rescue NetStatus::Exception => e
          raise Error::Controller, e.net_status
        end
      end

      def action
        method = get_controller
        opts = {}
        method.parameters.each do |req, name|
          if req.to_s.start_with? 'key'
            opt = config[name]
            self.help unless opt = @pos_args.shift if name == :name
            opts.merge!(name => opt)
          end
        end
        self.help unless @pos_args.empty? # only one position argument

        method.parameters.empty? ? method.call : method.call(**opts)
      end

      def get_controller
        def get_subcontroller_option
          key = :"#{self.class.get_splited_class_name.first}_name"
          config[key] unless config[key].nil?
        end

        def get_method(m_name, node)
          params = node.instance_method(:initialize).parameters

          opts = {}
          params.each do |req, name|
            if req.to_s.start_with? 'key'
              if name == :name
                opt = get_subcontroller_option
              elsif config.key? name
                opt = config[name]
              end
              opts.merge!(name => opt) unless opt.nil?
            end
          end

          CONTROLLER_BASE_OPTIONS.each { |opt| opts.merge!(opt => config[opt]) unless config[opt].nil? }
          opts.merge!(logger: @logger)
          node.new(**opts).method(m_name)
        end

        names = self.class.get_splited_class_name
        node = names.one? ? CONTROLLERS_MODULE::Base : CONTROLLERS_MODULE

        names.each do |n|
          c_name = n.capitalize.to_sym
          m_name = n.to_sym

          if node.respond_to? :constants and node.constants.include? c_name
            node = node.const_get(c_name)
          elsif node.respond_to? :instance_methods and node.instance_methods(false).include? m_name
            return get_method(m_name, node)
          end
        end
        raise NetStatus::Exception, { message: 'Method doesn\'t found' }
      end

      class << self
        def start(args)
          def clear_args(args, cmd)
            split_toggle_case_name(cmd).length.times{ args.shift }
            args
          end

          self.prepend
          cmd, node = get_cmd_and_node(args)
          args = clear_args(args, cmd)
          cmd.new(args, node).run
        end

        def prepend
          set_commands_hierarchy
          set_banners
          i18n_initialize
        end

        def set_banners(node=@@commands_hierarchy, path=[])
          node.each do |k,v|
            path_ = path.dup
            path_ << k
            if v.is_a? Hash
              set_banners(v, path_)
            else
              v.banner("sx #{path_.join(' ')}#{" <#{path.last}>" if v.has_required_param?}#{' (options)' unless v.options.empty?}")
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

          @@commands_hierarchy = get_commands.sort_by {|k1, k2| split_toggle_case_name(k1).one? ? 0 : 1 }.inject({}) do |h,k|
            node = h
            parts = split_toggle_case_name(k)
            parts.each do |cmd|
              node = (node[cmd] ||= (cmd == parts.last) ? COMMANDS_MODULE.const_get(k) : {})
            end
            h
          end
        end

        def get_splited_class_name
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
                raise Error::AmbiguousCommand.new(path: path, commands: res)
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
