require 'codeclimate-test-reporter'

CodeClimate::TestReporter.start

require 'bundler/setup'

Bundler.setup

require 'active_support'

require 'superhosting'

Superhosting::Helper::I18n.i18n_initialize

require 'helper/base'
require 'helper/expect'
require 'controller/spec_helpers'

require 'controller/container/spec_helpers'
require 'controller/user/spec_helpers'
require 'controller/admin/spec_helpers'
require 'controller/site/spec_helpers'
require 'controller/mux/spec_helpers'
require 'controller/base/spec_helpers'
require 'controller/model/spec_helpers'
require 'controller/mysql/spec_helpers'

def logger
  Logger.new(STDOUT).tap do |logger|
    logger.level = Logger::DEBUG
    logger.formatter = proc { |_severity, _datetime, _progname, msg| format("%s\n", msg.to_s) }
  end
end

RSpec.configure do |c|
  c.before(:example, :docker) { @with_docker = true }
  Thread.current[:logger] = logger
  Thread.current[:debug] = true
end
