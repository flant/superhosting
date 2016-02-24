module Superhosting
  class Base
    def initialize(logger: nil)
      setup_logger(logger)
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
    end

    def setup_logger(logger)
      @logger = logger
    end
  end
end