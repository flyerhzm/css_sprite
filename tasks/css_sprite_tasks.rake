namespace :css_sprite do
  require File.join(File.dirname(__FILE__), '../lib/css_sprite')
  
  desc "buid css sprite image"
  task :build do
    CssSprite.new.build
  end
end
