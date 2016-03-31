module Superhosting
  module Helper
    module Logger
      def logger
        Thread.current[:superhosting_logger]
      end

      def dry_run
        Thread.current[:superhosting_dry_run]
      end

      def debug(msg=nil, indent: true, desc: nil, &b)
        unless logger.nil?
          unless desc.nil?
            (desc[:data] ||= {})[:msg] = msg
            msg = t(desc: desc)
          end
          msg = indent ? with_indent(msg) : msg.strip
          logger.debug(msg, &b)
        end
        {} # net_status
      end

      def debug_operation(desc: nil, &b)
        old = self.indent

        status = :failed
        diff = nil
        resp = b.call do |resp|
          status = resp[:code]
          diff = resp[:diff]
        end

        resp
      rescue Exception => e
        raise
      ensure
        desc[:code] = :"#{desc[:code]}.#{status}"
        self.debug(desc: desc)
        self.debug(diff, indent: false) unless diff.nil?
        self.indent = old
      end

      def debug_block(desc: nil, operation: false, &b)
        old = self.indent

        self.debug(desc: desc)
        self.indent_step

        status = :failed
        resp = yield
        status = :ok

        resp
      rescue Exception => e
        raise
      ensure
        self.debug(desc: { code: status })
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
        "#{ind}#{msg.to_s.sub("\n", "\n#{ind}")}"
      end
    end
  end
end
