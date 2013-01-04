# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sirsidynix/version'
require 'base64'

Gem::Specification.new do |gem|
  gem.name           = "sirsidynix"
  gem.version        = Sirsidynix::VERSION
  gem.authors        = ["Mark Cooper"]
  gem.email          = Base64.decode64("bWFya2NocmlzdG9waGVyY29vcGVyQGdtYWlsLmNvbQ==\n")
  gem.description    = %q{Work with Sirsidynix APIs}
  gem.summary        = %q{Wrapper around Sirsidynix APIs}
  gem.homepage       = "http://www.libcode.net"

  gem.files          = `git ls-files`.split($/)
  gem.executables    = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files     = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths  = ["lib"]
  
  gem.add_dependency "nokogiri"
end
