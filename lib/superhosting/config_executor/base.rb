module Superhosting
  module ConfigExecutor
    class Base
      include Helpers

      attr_accessor :commands
      attr_accessor :model, :lib, :etc, :docker_api

      def initialize(model:, lib:, etc:, docker_api:, **kwargs)
        kwargs.each do |k, v|
          instance_variable_set("@#{k}", v)
          self.class.class_eval("attr_accessor :#{k}")
        end

        self.commands = []
        self.model = model
        self.lib = lib
        self.etc = etc
        self.docker_api = docker_api
      end

      def execute(script)
        instance_eval(script, script.path.to_s)
      end
    end
  end
end
