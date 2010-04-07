require 'rubygems'
require File.join(File.dirname(__FILE__), 'css_sprite/sprite.rb')

# We need Rails.root, but not require 'rails', so hack it
class Rails
  def self.root
    Dir.pwd
  end
end

sprite = Sprite.new
loop do
  sleep 1
  
  sprite.check
end