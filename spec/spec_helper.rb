require 'rubygems'
require 'rspec/autorun'
require 'date'
require 'mocha/api'

class Rails
  def self.root
    File.dirname(__FILE__)
  end
end

IMAGE_PATH = File.expand_path(File.join(Rails.root, 'public/images'))
STYLESHEET_PATH = File.expand_path(File.join(Rails.root, 'public/stylesheets'))
require File.join(File.dirname(__FILE__), '/../lib/css_sprite.rb')
