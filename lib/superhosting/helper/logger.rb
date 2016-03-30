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

      def debug_block(desc: nil, &b)
        self._debug_block(desc: desc, operation: false, &b)
      end

      def debug_operation(desc: nil, &b)
        self._debug_block(desc: desc, operation: true, &b)
      end

      def _debug_block(desc: nil, operation: false, &b)
        msg='FAILED'
        old = self.indent
        resp = {}

        unless operation
          self.debug(desc: desc)
          self.indent_step
        end

        resp = yield unless self.dry_run
        msg = 'OK'

        resp
      rescue Exception => e
        raise
      ensure
        if operation
          self.debug(msg, desc: desc)
        else
          self.debug(msg)
        end
        self.indent = old
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
        ind = "#{' ' * 4 * self.indent }"
        "#{ind}#{msg.sub("\n", "\n#{ind}")}"
      end
    end
  end
end
