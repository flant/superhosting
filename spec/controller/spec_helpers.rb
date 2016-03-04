module SpecHelpers
  module Base
    include Superhosting::Helpers

    def method_missing(m, *args, &block)
      if (m.to_s.start_with? 'not_')
        method = m[/(?<=not_)(.*)/]
        return reverse_expect(method, *args, &block) if respond_to? method
      end
      super
    end

    def reverse_expect(m, *args, &block)
      expect { send(:"#{m}", *args, &block) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    def expect_dir(path_mapper)
      expect(File.directory? path_mapper._path).to be_truthy
    end

    def expect_file(path_mapper)
      expect(File.file? path_mapper._path).to be_truthy
    end

    def expect_in_file(path_mapper, line)
      expect(check_in_file(path_mapper._path, line)).to be_truthy
    end

    def expect_group(name)
      expect { Etc.getgrnam(name) }.not_to raise_error
    end

    def expect_user(name)
      expect { Etc.getpwnam(name) }.not_to raise_error
    end

    def expect_file_owner(path_mapper, owner)
      expect(File.stat(path_mapper._path).gid).to be owner.gid
    end

    def expect_net_status_ok(hash)
      expect(hash).to_not include(:error)
    end
  end
end # SpecHelpers
