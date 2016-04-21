module Superhosting
  module Helper
    module I18n
      def i18n_initialize
        ::I18n.load_path << "#{::File.dirname(::File.dirname(__FILE__))}/config/net_status.yml"
        ::I18n.reload!
        ::I18n.locale = :en
      end
    end
  end
end

Superhosting::Helper::I18n.send(:extend, Superhosting::Helper::I18n)
