module Superhosting
  module Helper
    module Cmd
      def command!(*command_args, desc: {})
        self._command(*command_args, desc: desc) do |cmd|
          raise NetStatus::Exception.new(error: :error, code: :command_with_error, data: { error: [cmd.stdout, cmd.stderr].join("\n") })
        end
      end

      def command(*command_args, desc: {})
        self._command(command_args, desc)
      end

      def _command(*command_args, desc: {})
        (desc[:data] ||= {})[:command] = command_args.join
        desc[:code] ||= :command
        self.debug(desc: desc)

        cmd = Mixlib::ShellOut.new(*command_args)
        cmd.run_command

        yield cmd if block_given? and !cmd.status.success?
      end
    end
  end
end
