module Superhosting
  module Cli
    module Cmd; end
    class Base
      include Mixlib::CLI

      COMMANDS_MODULE = Cmd
      CONTROLLERS_MODULE = Superhosting::Controllers

      banner "#{?# * 100}\n#{?# * 49}SX#{?# * 49}\n#{?# * 100}\n\n"

      option :verbosity,
             :short => '-v',
             :long  => '--verbose',
             :description => 'More verbose output. Use twice for max verbosity'

      option :help,
             :short        => '-h',
             :long         => '--help',
             :description  => 'Show this message'

      def initialize(argv, node)
        super()

        @pos_args = parse_options(argv)
        @node = node

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

        print opt_parser.to_s

        print "\n"
        print get_childs_banners(@node) if (@node.is_a? Hash)
        print "\n"
      end

      def run
        method = get_controller

        opts = {}
        method.parameters.each do |req, name|
          if req.to_s.start_with? 'key'
            opt = config[name]

            if opt.nil? and name.to_s.end_with? 'name'
              res = config.keys.select {|k| k.to_s.end_with? 'name' }
              opt = config[res.first] if res.one?
            end

            opts.merge!(name => opt)
          end
        end

        method.call(**opts)
      end

      def get_controller
        node = CONTROLLERS_MODULE
        names = self.class.split_toggle_case_name(self.class.name.split('::').last)

        names.each do |n|
          c_name = n.capitalize.to_sym
          m_name = n.to_sym

          if node.respond_to? :constants and node.constants.include? c_name
            node = node.const_get(c_name)
          elsif node.respond_to? :instance_methods and node.instance_methods(false).include? m_name
            params = node.instance_method(:initialize).parameters

            args = []
            params.each do |req, name|
              arg = @pos_args.shift
              raise Errors::Base.new('You must supply required parameter') if arg.nil?

              if req == :req
                args << arg
              elsif req == :reqkey
                args << { name => arg }
              end
            end

            return node.new(*args).method(m_name)
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
          set_banners(@@commands_hierarchy)
        end

        def set_banners(node, path=[])
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