namespace :css_sprite do  
  desc "buid css sprite image"
  task :build do
    Sprite.new.build
  end
end
