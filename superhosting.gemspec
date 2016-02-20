lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'superhosting/version'

Gem::Specification.new do |spec|
  spec.name          = "superhosting"
  spec.version       = Superhosting::VERSION
  spec.authors       = ["Алексей Игрычев"]
  spec.email         = ["alexey.igrychev@flant.ru"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['sx']

  spec.add_dependency 'mixlib-cli'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
end
