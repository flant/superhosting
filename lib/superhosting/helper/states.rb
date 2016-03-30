module Superhosting
  module Helper
    module States
      def on_state(states:, state_mapper:, **options)
        current_state = state_mapper.state default: :none

        while (state = states[current_state.to_sym]) do
          method = state[:action]
          opts = method_options(method, options)

          self.debug_block(desc: { code: :transition, data: { name: method } }) do
            unless (resp = self.send(method, opts)).net_status_ok?
              resp.net_status_ok!
            end

            break if state[:next].nil?
            state_mapper.state.put!(current_state)
          end
          current_state = state[:next]
        end
        {}
      rescue Exception => e
        undo_method = state[:undo] || :"undo_#{method}"

        self.debug_block(desc: { code: :transition_undo, data: { name: undo_method } }) do
          if respond_to? undo_method
            opts = method_options(undo_method, options)
            self.send(undo_method, opts)
          end
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
