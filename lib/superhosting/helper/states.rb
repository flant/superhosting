module Superhosting
  module Helper
    module States
      def on_state(states:, state_mapper:, **options)
        current_state = state_mapper.state default: :none

        while (state = states[current_state.to_sym]) do
          method = state[:action]
          opts = method_options(method, options)

          self.debug("Current state '#{current_state}'.")

          unless (resp = self.send(method, opts)).net_status_ok?
            resp.net_status_ok!
          end

          self.debug("Transition '#{method}': launched.")

          break if (current_state = state[:next]).nil?
          state_mapper.state.put!(current_state)
        end
        {}
      rescue Exception => e
        self.debug("Transition '#{method}': crashed.")

        undo_method = state[:undo] || :"undo_#{method}"
        if respond_to? undo_method
          opts = method_options(undo_method, options)
          self.send(undo_method, opts)

          self.debug("Transition '#{undo_method}': launched.")
        end

        raise
      end

      def method_options(method_name, options)
        method = self.method(method_name)
        opts = {}
        method.parameters.each do |req, name|
          opt = options[name]
          opts.merge!(name => opt)
        end
        opts
      end
    end
  end
end
