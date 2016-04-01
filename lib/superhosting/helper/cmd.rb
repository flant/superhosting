module Superhosting
  module Helper
    module Cmd
      def command!(*command_args, debug: true)
        self._command(*command_args, debug: debug) do |cmd|
          raise NetStatus::Exception.new(error: :error, code: :command_with_error, data: { error: [cmd.stdout, cmd.stderr].join("\n") })
        end
      end

      def command(*command_args, debug: true)
        self._command(command_args, debug: debug)
      end

      def _command(*command_args, debug:)
        desc = { code: :command, data: { command: command_args.join } }
        if debug
          self.debug_operation(desc: desc) do |&blk|
            self._command_without_debug(*command_args)
            blk.call(code: :ok)
          end
        else
          self._command_without_debug(*command_args)
        end
        {} # net_status
      end

      def _command_without_debug(*command_args)
        self.with_dry_run do |dry_run|
          unless dry_run
            cmd = Mixlib::ShellOut.new(*command_args)
            cmd.run_command
            yield cmd if block_given? and !cmd.status.success?
          end
        end
      end
    end
  end
end
