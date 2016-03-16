module Superhosting
  module ScriptExecutor
    class Site < Container
      attr_accessor :site_name, :site

      def initialize(site_name:, site:, site_lib:, site_web:, **kwargs)
        self.site_name = site_name
        self.site = ConfigMapper::Site.new(etc_mapper: site, lib_mapper: site_lib, web_mapper: site_web)
        super(**kwargs)
      end

      def base_mapper
        self.site
      end
    end
  end
end