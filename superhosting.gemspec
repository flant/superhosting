lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'superhosting/version'

Gem::Specification.new do |spec|
  spec.name          = "superhosting"
  spec.version       = Superhosting::VERSION
  spec.authors       = ["Алексей Игрычев"]
  spec.email         = ["alexey.igrychev@flant.ru"]

  spec.summary       = "The tool for web hosting using docker containers"
  spec.description   = "#{spec.summary}."
  spec.license       = "MIT"
  spec.homepage      = "https://github.com/flant/path_mapper"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['sx']

  spec.required_ruby_version = '>= 2.2.1'

  spec.add_dependency 'mixlib-cli', '>= 1.5.0', '< 2.0'
  spec.add_dependency 'mixlib-shellout', '>= 2.2.6', '< 3.0'
  spec.add_dependency 'path_mapper', '>= 0.0.1', '< 1.0'
  spec.add_dependency 'net_status', '>= 0.0.1', '< 1.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4', '>= 3.4.0'
  spec.add_development_dependency 'excon', '>= 0.45.4', '< 1.0'
  spec.add_development_dependency 'pry', '>= 0.10.3', '< 1.0'
  spec.add_development_dependency 'pry-byebug', '>= 3.3.0', '< 4.0'
  spec.add_development_dependency 'pry-stack_explorer', '>= 0.4.9.2', '< 1.0'
  spec.add_development_dependency 'travis', '~> 1.8', '>= 1.8.2'
end
