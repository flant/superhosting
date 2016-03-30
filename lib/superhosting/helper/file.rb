module Superhosting
  module Helper
    module File
      def safe_link!(path_to, path)
        unless ::File.exist? path
          self.pretty_debug(desc: {code: :symlink_create, data: { path_to: path_to, path: path } }) do
            ::File.symlink(path_to, path)
          end
        end
      end

      def safe_unlink!(path)
        if ::File.exist? path
          self.pretty_debug(desc: {code: :symlink_remove, data: { path: path } }) do
            ::File.unlink(path)
          end
        end
      end

      def chown_r!(user, group, path) # TODO
        FileUtils.chown_R user, group, path
      end
    end
  end
end
