module Superhosting
  module ConfigExecutor
    def self.new(**kwargs)
      klass = if kwargs[:container].nil?
                Mux
              elsif kwargs[:site].nil?
                Container
              else
                Site
              end
      klass.new(kwargs)
    end
  end
end
