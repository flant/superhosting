module Superhosting
  module Helper
    module Cmd
      def run_command(*command_args)
        cmd = Mixlib::ShellOut.new(*command_args)
        cmd.run_command
        cmd
      end

      def run_command!(*command_args)
        cmd = run_command(*command_args)
        unless cmd.status.success?
          raise NetStatus::Exception.new(error: :error, code: :command_with_error, data: { error: [cmd.stdout, cmd.stderr].join("\n") })
        end
      end
    end
  end
end
