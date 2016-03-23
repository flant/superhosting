module Superhosting
  module Helper
    module Logger
      def logger
        Thread.current[:superhosting_logger]
      end

      def debug(msg=nil, desc: nil, &b)
        unless logger.nil?
          unless desc.nil?
            (desc[:data] ||= {})[:msg] = msg
            msg = t(desc: desc)
          end
          logger.debug(msg, &b)
        end
        {} # net_status
      end

      def t(desc: {}, context: nil)
        code = desc[:code] || :default
        data = desc[:data]
        ::I18n.t [:command, context, code].join('.'), [:command, code].join('.'), **data, raise: true
      rescue ::I18n::MissingTranslationData => e
        raise NetStatus::Exception, { code: :missing_translation, data: { code: code } }
      end
    end
  end
end
