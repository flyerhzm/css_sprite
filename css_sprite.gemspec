# -*- encoding: utf-8 -*-
require File.expand_path('../lib/css_sprite/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Richard Huang"]
  gem.email         = ["flyerhzm@gmail.com"]
  gem.description   = %q{css_sprite is a rails plugin/gem to generate css sprite image automatically.}
  gem.summary       = %q{css_sprite is a rails plugin/gem to generate css sprite image automatically.}
  gem.homepage      = "https://github.com/flyerhzm/css_sprite"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "css_sprite"
  gem.require_paths = ["lib"]
  gem.version       = CssSprite::VERSION

  gem.add_dependency("rmagick")
  gem.add_runtime_dependency("rspec")
  gem.add_runtime_dependency("mocha")
end
