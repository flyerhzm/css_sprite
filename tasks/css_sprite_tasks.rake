require File.join(File.dirname(__FILE__), '../lib/css_sprite/sprite.rb')

namespace :css_sprite do  
  desc "buid css sprite image"
  task :build do
    Sprite.new.build
  end
end
