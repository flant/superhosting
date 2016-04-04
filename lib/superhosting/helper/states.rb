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

            self.with_logger(logger: false) do
              if (state[:next]).nil?
                state_mapper.state.delete!(full: true)
              else
                state_mapper.state.put!(state[:next])
              end
            end
            self.debug(desc: { code: :change_state, data: { from: current_state, to: state[:next] } })
          end
          break if (current_state = state[:next]).nil?
        end
        {}
      rescue Exception => e
        undo_method = state[:undo] || :"undo_#{method}"

        if respond_to? undo_method
          self.debug_block(desc: { code: :transition_undo, data: { name: undo_method } }) do
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

      def state(name:)
        self.existing_validation(name: name).net_status_ok!
        self.index[name][:state_mapper]
      end

      def set_state(name:, state:) # TODO
        self.with_logger(logger: false) do
          if state.nil?
            self.state(name: name).delete!(full: full)
          else
            self.state(name: name).put!(state)
          end
        end
        self.debug(desc: { code: :change_state, data: { from: self.state(name: name).value, to: state } })
      end
    end
  end
end
