# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "xcpretty-phabricator-formatter"
  spec.version       = "0.0.4"
  spec.authors       = ["Valerii Hiora"]
  spec.email         = ["valerii.hiora@gmail.com"]
  spec.description   =
  %q{
  Formatter for xcpretty customized to provide pretty output for Phabricator
  }
  spec.summary       = %q{xcpretty custom formatter for Phabricator}
  spec.homepage      = "https://github.com/vhbit/xcpretty-phabricator-formatter"
  spec.license       = "MIT"
  spec.required_ruby_version = "~> 2.0"
  spec.files         = [
  	"README.md",
  	"LICENSE",
  	"lib/phabricator_formatter.rb",
  	"bin/xcpretty-phabricator-formatter"]
  spec.executables   = ["xcpretty-phabricator-formatter"]
  spec.require_paths = ["lib"]
  spec.add_dependency "xcpretty", "~> 0.2", ">= 0.0.7"
  spec.add_dependency "json", '1.8.3'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "bacon", "~> 1.2"
end
