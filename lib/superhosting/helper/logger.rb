module Superhosting
  module Helper
    module Logger
      def __logger
        Thread.current[:logger]
      end

      def __logger=(val)
        Thread.current[:logger] = val
      end

      def with_logger(logger: nil)
        old = __logger
        self.__logger = nil if logger.is_a? FalseClass
        yield
      ensure
        self.__logger = old
      end

      def __dry_run
        Thread.current[:dry_run]
      end

      def __dry_run=(val)
        Thread.current[:dry_run] = val
      end

      def with_dry_run
        old = __dry_run
        yield old
      ensure
        __dry_run = old
      end

      def storage
        Thread.current[:dry_storage] ||= {}
      end

      def __debug
        Thread.current[:debug]
      end

      def info(msg = nil, indent: true, **_kwargs, &b)
        unless __logger.nil?
          msg = indent ? with_indent(msg) : msg.chomp
          __logger.info(msg, &b)
        end
        {} # net_status
      end

      def debug(msg = nil, indent: true, desc: nil, &b)
        unless __logger.nil?
          unless desc.nil?
            (desc[:data] ||= {})[:msg] = msg
            msg = t(desc: desc)
          end
          msg = indent ? with_indent(msg) : msg.chomp
          __logger.debug(msg, &b)
        end
        {} # net_status
      end

      def debug_operation(desc: nil, &b)
        old = indent

        status = :failed
        diff = nil
        resp = b.call do |res|
          status = res[:code] || :ok
          diff = res[:diff]
        end

        resp
      rescue StandardError => _e
        raise
      ensure
        desc[:code] = :"#{desc[:code]}.#{status}"
        debug(desc: desc)
        debug(diff, indent: false) if !diff.nil? && __debug
        self.indent = old
      end

      def debug_block(desc: nil)
        old = indent

        debug(desc: desc)
        indent_step

        status = :failed
        resp = yield
        status = :ok

        resp
      rescue StandardError => _e
        raise
      ensure
        debug(desc: { code: status })
        self.indent = old
      end

      def t(desc: {}, context: nil)
        code = desc[:code]
        data = desc[:data]
        ::I18n.t [:debug, context, code].join('.'), [:debug, code].join('.'), **data, raise: true
      rescue ::I18n::MissingTranslationData => _e
        raise NetStatus::Exception, code: :missing_translation, data: { code: code }
      end

      def indent
        @@indent ||= indent_reset
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
        ind = (' ' * 4 * self.indent).to_s
        "#{ind}#{msg.to_s.sub("\n", "\n#{ind}")}"
      end
    end
  end
end
