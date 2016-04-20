module SpecHelpers
  module Base
    include Superhosting::Helpers
    include Helper::Base
    include Helper::Expect

    def with_base(action, default: {}, to_yield: [], to_delete: {}, **options)
      opts = default.merge!(options)
      name = opts.delete(:name)
      yield_args = to_yield.empty? ? [name] : to_yield
      delete_kwargs = to_delete.empty? ? { name: name } : to_delete
      with_logger(logger: false) { self.send("#{action}_add_with_exps", name: name, **opts) }
      yield *yield_args if block_given?
      with_logger(logger: false) { self.send("#{action}_delete_with_exps", **delete_kwargs) }
    end
  end
end
