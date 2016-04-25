module Superhosting
  module Helper
    module Cmd
      def command!(*command_args, **kwargs)
        _command(*command_args, **kwargs) do |cmd|
          raise NetStatus::Exception, error: :error, code: :command_with_error, data: { error: [cmd.stdout, cmd.stderr].join("\n") }
        end
      end

      def command(*command_args, **kwargs)
        _command(command_args, **kwargs)
      end

      def _command(*command_args, debug: true, logger: nil, &b)
        with_logger(logger: logger) do
          desc = { code: :command, data: { command: command_args.join } }
          if debug
            debug_operation(desc: desc) do |&blk|
              _command_without_debug(*command_args, &b)
              blk.call(code: :ok)
            end
          else
            _command_without_debug(*command_args, &b)
          end
          {} # net_status
        end
      end

      def _command_without_debug(*command_args)
        with_dry_run do |dry_run|
          unless dry_run
            cmd = Mixlib::ShellOut.new(*command_args)
            cmd.run_command
            yield cmd if block_given? && !cmd.status.success?
          end
        end
      end
    end
  end
end
