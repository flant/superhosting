module Superhosting
  module Helper
    module File
      def pretty_override(path, line)
        pretty_remove(path, line)
        pretty_write(path, line)
        {} # net_status_ok
      end

      def pretty_write(path, line)
        self.file_append(path, line) unless self.check_in_file(path, line)
        {} # net_status_ok
      end

      def file_append(path, content)
        ::File.open(path, 'a+') {|f| f.puts(content) }
        {} # net_status_ok
      end

      def pretty_remove(path, line)
        if ::File.exists? path
          lines = ::File.readlines(path).select {|l| l !~ Regexp.new(line) and l }
          if lines.empty?
            ::File.delete(path)
            self.debug("File '#{path}': removed.")
          else
            ::File.open(path, 'w') { |f| f.puts lines.join('') }
          end
        end
        {} # net_status_ok
      end

      def check_in_file(path, line)
        if ::File.exists? path
          ::File.readlines(path).any? { |l| l =~ Regexp.new(line) }
        else
          false
        end
      end

      def file_link(path, path_to)
        ::File.symlink(path, path_to)
        self.debug(desc: {code: :symlink_create, data: { from: path, to: path_to} })
      end

      def file_unlink(path)
        ::File.unlink(path)
        self.debug(desc: {code: :symlink_remove, data: { path: path } })
      end

      def chown_r(user, group, path)
        FileUtils.chown_R user, group, path
      end
    end
  end
end
