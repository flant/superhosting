module Superhosting
  module Helper
    module File
      def safe_link!(path_to, path)
        debug_operation(desc: { code: :symlink, data: { path_to: path_to, path: path } }) do |&blk|
          if ::File.exist? path
            blk.call(code: :ok)
          else
            with_dry_run do |dry_run|
              ::File.symlink(path_to, path) unless dry_run
              blk.call(code: :created)
            end
          end
        end
      end

      def safe_unlink!(path)
        if ::File.symlink? path
          debug_operation(desc: { code: :symlink, data: { path: path } }) do |&blk|
            with_dry_run do |dry_run|
              ::File.unlink(path) unless dry_run
              blk.call(code: :deleted)
            end
          end
        end
      end

      def chown_r!(user, group, path)
        debug_operation(desc: { code: :chown_r, data: { user: user, group: group, path: path } }) do |&blk|
          with_dry_run do |dry_run|
            FileUtils.chown_R(user, group, path) unless dry_run
            blk.call(code: :ok)
          end
        end
      end

      def chown!(user, group, path)
        debug_operation(desc: { code: :chown, data: { user: user, group: group, path: path } }) do |&blk|
          with_dry_run do |dry_run|
            FileUtils.chown(user, group, path) unless dry_run
            blk.call(code: :ok)
          end
        end
      end

      def chmod!(mode, path)
        debug_operation(desc: { code: :chmod, data: { mode: mode, path: path } }) do |&blk|
          with_dry_run do |dry_run|
            FileUtils.chmod(mode, path) unless dry_run
            blk.call(code: :ok)
          end
        end
      end
    end
  end
end
