module Superhosting
  module Helper
    module File
      def file_append(path, content)
        ::File.open(path, 'a+') {|f| f.puts(content) }
        {} # net_status_ok
      end

      def pretty_write(path, line)
        self.file_append(path, line) unless self.check_in_file(path, line)
        {} # net_status_ok
      end

      def pretty_override(path, line)
        pretty_remove(path, line)
        pretty_write(path, line)
        {} # net_status_ok
      end

      def pretty_remove(path, line)
        if ::File.exists? path
          lines = ::File.readlines(path).select {|l| l !~ Regexp.new(line) }
          ::File.open(path, 'w') {|f| f.write lines.join('') }
        end
        ::File.delete(path) if ::File.zero?(path)
        {} # net_status_ok
      end

      def check_in_file(path, line)
        if ::File.exists? path
          ::File.readlines(path).any? { |l| l =~ Regexp.new(line) }
        else
          false
        end
      end
    end
  end
end
