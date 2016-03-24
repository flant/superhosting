module Superhosting
  module Helper
    module States
      def on_state(states:, state_mapper:, **options)
        state = state_mapper.state default: :none

        if block_given?
          unless (resp = yield).net_status_ok?
            return resp
          end
        end

        while (state = states[state.to_sym]) do
          method = state[:action]
          opts = method_options(method, options)
          unless (resp = self.send(method, opts)).net_status_ok?
            resp.net_status_ok!
          end

          self.debug("State method '#{method}': launched.")

          break if (state = state[:next]).nil?
          state_mapper.state.put!(state)
        end
        {}
      rescue Exception => e
        self.debug("State method '#{method}': crashed.")

        undo_method = state[:undo] || :"undo_#{method}"
        if respond_to? undo_method
          opts = method_options(undo_method, options)
          self.send(undo_method, opts)

          self.debug("State method '#{undo_method}': launched.")
        end

        return e.net_status
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