module Superhosting
  module ConfigExecutor
    def self.new(**kwargs)
      klass = if kwargs[:site].nil?
        Container
      else
        Site
      end
      klass.new(kwargs)
    end
  end
end