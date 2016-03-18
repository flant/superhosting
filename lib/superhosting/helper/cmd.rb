module Superhosting
  module Helper
    module Cmd
      def run_command(*command_args)
        cmd = Mixlib::ShellOut.new(*command_args)
        cmd.run_command
        cmd
      end
    end
  end
end
