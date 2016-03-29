module Superhosting
  module Helper
    module File
      def safe_link!(path_to, path)
        unless ::File.exist? path
          ::File.symlink(path_to, path)
          self.debug(desc: {code: :symlink_create, data: { path_to: path_to, path: path } })
        end
      end

      def safe_unlink!(path)
        if ::File.exist? path
          ::File.unlink(path)
          self.debug(desc: {code: :symlink_remove, data: { path: path } })
        end
      end

      def chown_r!(user, group, path)
        FileUtils.chown_R user, group, path
      end
    end
  end
end
