module Superhosting
  module Helper
    module File
      def file_write(path, content='')
        if ::File.exists? path
          self.file_append(path, content)
        else
          ::File.open(path, 'w') {|f| f.write(content) }
        end
      end

      def file_append(path, content)
        ::File.open(path, 'a+') {|f| f.puts(content) }
      end

      def pretty_write(path, line)
        self.file_append(path, line) unless self.check_in_file(path, line)
      end

      def pretty_remove(path, line)
        if ::File.exists? path
          lines = ::File.readlines(path).select {|l| l !~ Regexp.new(line) }
          ::File.open(path, 'w') {|f| f.write lines.join('') }
        end
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
