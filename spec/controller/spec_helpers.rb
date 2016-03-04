module SpecHelpers
  module Base
    include Superhosting::Helpers

    def expect_dir(path)
      path = (path.respond_to?(:_path)) ? path._path : path
      expect(File.directory? path).to be_truthy
    end

    def expect_file(path)
      path = (path.respond_to?(:_path)) ? path._path : path
      expect(File.file? path).to be_truthy
    end

    def expect_in_file(path, line)
      path = (path.respond_to?(:_path)) ? path._path : path
      expect(check_in_file(path, line)).to be_truthy
    end

    def expect_group(name)
      expect { Etc.getgrnam(name) }.not_to raise_error
    end

    def expect_user(name)
      expect { Etc.getpwnam(name) }.not_to raise_error
    end

    def expect_file_owner(path, owner)
      path = (path.respond_to?(:_path)) ? path._path : path
      expect(File.stat(path).gid).to be owner.gid
    end
  end
end # SpecHelpers
