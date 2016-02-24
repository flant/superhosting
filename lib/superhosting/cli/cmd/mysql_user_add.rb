module Superhosting
  module Cli
    module Cmd
      class MysqlUserAdd < Base
        option :generate,
               :short => '-g',
               :long  => '--generate'
      end
    end
  end
end