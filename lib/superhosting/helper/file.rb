module Superhosting
  module Helper
    module File
      def safe_link!(path, path_to)
        unless ::File.exist? path_to
          ::File.symlink(path, path_to)
          self.debug(desc: {code: :symlink_create, data: { from: path, to: path_to} })
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
