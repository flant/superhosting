module Superhosting
  module Patches
    module PathMapper
      module Helper
        include Superhosting::Helper::Logger

        def _action!(code, data)
          debug_operation(desc: { code: code, data: data }) do |&blk|
            yield.tap { |res| blk.call(code: res[:code], diff: res[:d][:diff]) }
          end
        end
      end
    end
  end
end
