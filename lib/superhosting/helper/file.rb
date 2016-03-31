module Superhosting
  module Helper
    module File
      def safe_link!(path_to, path)
        unless ::File.exist? path
          self.debug_operation(desc: { code: :symlink, data: { path_to: path_to, path: path } }) do |&blk|
            ::File.symlink(path_to, path).tap do
              blk.call(code: :created)
            end
          end
        end
      end

      def safe_unlink!(path)
        if ::File.exist? path
          self.debug_operation(desc: { code: :symlink, data: { path: path } }) do |&blk|
            ::File.unlink(path).tap do
              blk.call(code: :deleted)
            end
          end
        end
      end

      def chown_r!(user, group, path) # TODO
        self.debug_operation(desc: { code: :chown_r, data: { user: user, group: group, path: path } }) do |&blk|
          FileUtils.chown_R(user, group, path).tap do
            blk.call(code: :ok)
          end
        end
      end

      def chown!(user, group, path)
        self.debug_operation(desc: { code: :chown, data: { user: user, group: group, path: path } }) do |&blk|
          FileUtils.chown(user, group, path).tap do
            blk.call(code: :ok)
          end
        end
      end

      def chmod!(mode, path)
        self.debug_operation(desc: { code: :chmod, data: { mode: mode, path: path } }) do |&blk|
          FileUtils.chmod(mode, path).tap do
            blk.call(code: :ok)
          end
        end
      end
    end
  end
end
