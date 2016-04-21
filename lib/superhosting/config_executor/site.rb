module Superhosting
  module ConfigExecutor
    class Site < Container
      attr_accessor :site

      def initialize(site:, **kwargs)
        self.site = site
        super(**kwargs)
      end

      protected

      def base_mapper
        site
      end
    end
  end
end
