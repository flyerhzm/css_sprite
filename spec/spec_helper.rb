require 'rubygems'
require 'rspec/autorun'
require 'date'
require 'mocha/api'

class Dir
  def self.pwd
    File.dirname(__FILE__)
  end
end

IMAGE_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'app/assets/images'))
STYLESHEET_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'app/assets/stylesheets'))
require File.join(File.dirname(__FILE__), '/../lib/css_sprite.rb')
