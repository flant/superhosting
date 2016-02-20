require 'mixlib/cli'

module Superhosting
  module Cli
    module Cmd; end
    class Base
      include Mixlib::CLI

      COMMANDS_MODULE = Cmd

      banner '### sx ###'

      verbosity_level = 0
      option :verbosity,
             :short => "-v",
             :long  => "--verbose",
             :description => "More verbose output. Use twice for max verbosity",
             :proc => Proc.new { verbosity_level += 1 },
             :default => 0

      option :help,
             :short        => "-h",
             :long         => "--help",
             :description  => "Show this message",
             :on           => :tail,
             :boolean      => true

      def initialize(argv, node)
        super()

        parse_options(argv)
        @node = node

        self.help if config[:help]
      end

      def help
        def get_childs_banners(node)
          def put_array(arr)
            arr.each do |s|
              if s.is_a? Array
                put_array(s)
              else
                p s
              end
            end
          end

          if node.is_a? Hash
            node.map do |k,v|
              if v.is_a? Hash
                get_childs_banners(node[k])
              else
                v.banner
              end
            end
            # end.join('\n')
          else
            node.banner
          end
        end

        def set_banners(node, commands=[])
          node.each do |k,v|
            commands << k
            if v.is_a? Hash
              set_banners(v, commands)
            else
              v.banner("sx #{commands.join(' ')} (options)")
            end
          end
        end

        p opt_parser.to_s
        if (@node.is_a? Hash)
          set_banners(@node)
          put_array(get_childs_banners(@node))
        end
        exit 1
      end

      def run
        self.help
      end

      class << self
        def start(args)
          cmd, node = get_cmd_and_node(args)
          cmd.new(args, node).run
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

          cmd_words = positional_arguments(args)
          if cmd = find_cmd(cmd_words.clone)
            [cmd, find_node(toggle_case_to_args(cmd.name.split('::').last))]
          else
            [self, find_node(cmd_words)]
          end
        end

        def find_node(names)
          node = get_commands_hierarchy
          names.each do |n|
            break unless node[n]
            node = node[n]
          end
          node
        end

        def toggle_case_to_args(klass)
          klass.to_s.gsub(/([[:lower:]])([[:upper:]])/, '\1 \2').split(' ').map(&:downcase)
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
      end
    end
  end
end