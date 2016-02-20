module Superhosting
  module Cli
    module Cmd; end
    class Base
      include Mixlib::CLI

      COMMANDS_MODULE = Cmd

      banner '##### SX #####'

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

        parse_options(argv)
        @node = node

        if config[:help]
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
        self.help
      end

      class << self
        def start(args)
          prepend
          cmd, node = get_cmd_and_node(args)
          cmd.new(args, node).run
        end

        def prepend
          set_banners(get_commands_hierarchy)
        end

        def get_cmd_and_node(args)
          def positional_arguments(args)
            args.select { |arg| arg =~ /^(([[:alnum:]])[[:alnum:]\_\-]+)$/ }
          end

          def find_cmd(words)
            def get_class(class_name)
              COMMANDS_MODULE.const_get(class_name)
            rescue NameError
              return false
            end

            match = nil
            until match || words.empty?
              candidate = words.map(&:capitalize).join
              unless match = get_class(candidate)
                words.pop
              end
            end
            match
          end

          def find_node(names)
            node = get_commands_hierarchy
            key = ''
            names.each do |n|
              break unless node[n]
              key = n
              node = node[n]
            end
            { key => node }
          end

          cmd_words = positional_arguments(args)
          if cmd = find_cmd(cmd_words.dup)
            [cmd, find_node(toggle_case_to_args(cmd.name.split('::').last))]
          else
            [self, find_node(cmd_words)]
          end
        end

        def get_commands_hierarchy
          def get_commands
            COMMANDS_MODULE.constants.select {|c| Class === COMMANDS_MODULE.const_get(c) }
          end

          get_commands.inject({}) do |h,k|
            node = h
            parts = toggle_case_to_args(k)
            parts.each do |cmd|
              node = (node[cmd] ||= (cmd == parts.last) ? COMMANDS_MODULE.const_get(k) : {})
            end
            h
          end
        end

        def toggle_case_to_args(klass)
          klass.to_s.gsub(/([[:lower:]])([[:upper:]])/, '\1 \2').split(' ').map(&:downcase)
        end

        def set_banners(node, strings=[])
          node.each do |k,v|
            commands = strings.dup
            commands << k
            if v.is_a? Hash
              set_banners(v, commands)
            else
              v.banner("sx #{commands.join(' ')} #{'(options)' unless v.options.empty?}")
            end
          end
        end
      end
    end
  end
end