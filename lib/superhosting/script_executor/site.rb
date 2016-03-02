module Superhosting
  module ScriptExecutor
    class Site < Container
      attr_accessor :site, :site_name

      def initialize(site:, site_name:, **kwargs)
        self.site = site
        self.site_name = site_name
        super(**kwargs)
      end
    end
  end
end