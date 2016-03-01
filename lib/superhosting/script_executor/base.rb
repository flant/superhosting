module Superhosting
  module ScriptExecutor
    class Base
      def initialize(**kwargs)
        kwargs.each do |k, v|
          instance_variable_set("@#{k}", v)
          self.class.class_eval("attr_accessor :#{k}")
        end
      end

      def instance_variables_to_hash
        self.instance_variables.map do |name|
          [name.to_s[1..-1].to_sym, self.instance_variable_get(name)]
        end.to_h
      end

      def execute(script)
        self.instance_eval(script)
      end
    end
  end
end