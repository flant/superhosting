module Superhosting
  module Helper
    module Erb
      def erb(node, vars)
        ERB.new(node).result(OpenStruct.new(vars).instance_eval { binding })
      rescue Exception => e
        raise NetStatus::Exception, e.net_status.merge!( message: "#{e.backtrace.first.sub! '(erb)', node._path}: #{e.message}")
      end
    end
  end
end
