module SpecHelpers
  module Helper
    module Expect
      def method_missing(m, *args, &block)
        if m.to_s.start_with? 'not_'
          method = m[/(?<=not_)(.*)/]
          return reverse_expect(method, *args, &block) if respond_to? method
        elsif m.to_s.include? '_with_exps'
          method = m[/(.*)(?=_with_exps)/]
          return method_with_expectation(method, *args, &block) if respond_to? method
        end
        super
      end

      def reverse_expect(expect_method, *args, &block)
        expect { send(:"#{expect_method}", *args, &block) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      def method_with_expectation(controller_method, *args)
        expectation_method = "#{controller_method}_exps"

        kwargs = args.extract_options!
        code = kwargs.delete(:code)

        resp = begin
          send(controller_method.to_sym, *args, **kwargs)
        rescue NetStatus::Exception => e
          e.net_status
        end

        expect_net_status(resp, code: code)
        if code
          expect_translation(resp)
        elsif respond_to? expectation_method
          send(expectation_method, **kwargs)
        end
        resp
      end

      def model_exps(m, **kwargs)
        send(m, kwargs) if respond_to? m
      end

      def expect_translation(resp)
        expect(resp.net_status_normalize).to include(:message)
      end

      def expect_dir(maybe_path)
        maybe_path = maybe_path.path if maybe_path.respond_to? :path
        expect(File.directory?(maybe_path)).to be_truthy
      end

      def expect_file(maybe_path)
        maybe_path = maybe_path.path if maybe_path.respond_to? :path
        expect(File.file?(maybe_path)).to be_truthy
      end

      def expect_in_file(path_mapper, line)
        expect(path_mapper.check(line)).to be_truthy
      end

      def expect_group(name)
        expect { Etc.getgrnam(name) }.not_to raise_error
      end

      def expect_user(name)
        expect { Etc.getpwnam(name) }.not_to raise_error
      end

      def expect_file_owner(maybe_path, owner_name)
        maybe_path = maybe_path.path if maybe_path.respond_to? :path
        owner = Etc.getgrnam(owner_name)
        expect(File.stat(maybe_path).gid).to be owner.gid
      end

      def expect_exception_code(_exc = NetStatus::Exception, code: nil)
        expect { yield }.to raise_error { |error| expect(error.net_status[:code]).to be(code) }
      end

      def expect_net_status(hash, code: nil)
        if code
          expect(hash).to include(code: code)
        else
          expect_net_status_ok(hash)
        end
      end

      def expect_net_status_ok(hash)
        expect(hash).to_not include(:error)
      end

      def expect_file_mtime(*file_path)
        files = file_path.map { |path| [path, File.mtime(path)] }
        yield
        files.each { |path, time| expect(time).to_not eq File.mtime(path) }
      end
    end
  end
end
