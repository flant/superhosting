module Superhosting
  class Base
    def initialize(logger: nil)
      @logger = logger
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
    end
  end
end