module Superhosting
  module Helper
    module Logger
      def logger
        Thread.current[:superhosting_logger]
      end

      def dry_run
        Thread.current[:superhosting_dry_run]
      end

      def debug(msg=nil, desc: nil, &b)
        unless logger.nil?
          unless desc.nil?
            (desc[:data] ||= {})[:msg] = msg
            msg = t(desc: desc)
          end
          logger.debug(with_indent(msg), &b)
        end
        {} # net_status
      end

      def pretty_debug(msg=nil, desc: nil, &b)
        resp = {}
        if block_given?
          self.debug(msg, desc: desc)
          self.indent_step
          resp = yield unless self.dry_run
          self.debug('OK')
          self.indent_step_back
        else
          self.debug(msg, desc: desc)
        end
        resp
      rescue Exception => e
        self.debug('FAILED')
        self.indent_step_back
        raise
      end

      def t(desc: {}, context: nil)
        code = desc[:code]
        data = desc[:data]
        ::I18n.t [:debug, context, code].join('.'), [:debug, code].join('.'), **data, raise: true
      rescue ::I18n::MissingTranslationData => e
        raise NetStatus::Exception, { code: :missing_translation, data: { code: code } }
      end

      def indent
        @@indent ||= self.indent_reset
      end

      def indent=(val)
        @@indent = val
      end

      def indent_reset
        self.indent = 0
      end

      def indent_step
        self.indent += 1
      end

      def indent_step_back
        self.indent -= 1
      end

      def with_indent(msg)
        ind = "#{'* ' * 2 * self.indent }"
        "#{ind}#{msg.sub("\n", "\n#{ind}")}"
      end
    end
  end
end
