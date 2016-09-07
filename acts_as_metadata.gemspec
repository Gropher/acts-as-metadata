# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "metadata/version"

Gem::Specification.new do |s|
  s.name        = "acts_as_metadata"
  s.version     = ActsAsMetadata::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Gropher"]
  s.email       = ["grophen@gmail.com"]
  s.homepage    = "https://github.com/Gropher/acts-as-metadata"
  s.summary     = %q{Additional on-demand fields for ActiveRecord models}
  s.description = %q{This gem allows to add additional database-stored fields to your models}

  s.rubyforge_project = "acts_as_metadata"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency('rails', '> 4.0' )
  s.add_development_dependency("rspec", ">= 2.0.0")
  s.add_development_dependency("sqlite3", '>= 1.3.5')
end
