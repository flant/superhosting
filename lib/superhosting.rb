require 'mixlib/cli'

require 'superhosting/version'

require 'superhosting/controller'
require 'superhosting/controllers/admin'
require 'superhosting/controllers/admin/container'
require 'superhosting/controllers/container'
require 'superhosting/controllers/container/admin'
require 'superhosting/controllers/mysql'
require 'superhosting/controllers/mysql/db'
require 'superhosting/controllers/mysql/user'
require 'superhosting/controllers/site'
require 'superhosting/controllers/site/alias'
require 'superhosting/controllers/user'

require 'superhosting/docker_api'

require 'superhosting/cli/errors/base'
Dir["#{File.dirname(__FILE__)}/superhosting/cli/errors/*.rb"].each{|cmd| require_relative cmd.split('.rb').first}

require 'superhosting/cli/base'
Dir["#{File.dirname(__FILE__)}/superhosting/cli/cmd/*.rb"].each{|cmd| require_relative cmd.split('.rb').first}