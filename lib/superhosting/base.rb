module Superhosting
  class Base
    def initialize(config_path: '/etc/sx', lib_path: '/var/lib/sx', logger: nil)
      @config_path = config_path
      @lib_path = lib_path
      @config = PathMapper::Mapper.new(@config_path)
      @lib = PathMapper::Mapper.new(@lib_path)
      @logger = logger
    end

    def debug(*a, &b)
      @logger.debug(*a, &b) unless @logger.nil?
    end
  end
end