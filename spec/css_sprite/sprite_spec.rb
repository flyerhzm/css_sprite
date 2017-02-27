require 'spec_helper'

RSpec.describe Sprite do
  before(:context) do
    @sprite = Sprite.new
    @directory_path = File.join(IMAGE_PATH, 'css_sprite')
  end

  describe "build" do
    it "should build css_sprite image and css" do
      Sprite.any_instance.expects(:system).with("optipng -o 1 #{IMAGE_PATH}/css_sprite.png").never
      Sprite.new.build
    end

    it "should build css_sprite image and sass" do
      Sprite.new('engine' => 'sass').build
    end

    it "should build another image_type" do
      Sprite.new('image_type' => 'PaletteType').build
    end

    it "should do optimization" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('optimization' => true).build
    end

    it "should build another image optimization" do
      Sprite.any_instance.expects(:system).with("optipng -o 1 #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('optimization' => "optipng -o 1").build
    end

    it "should output css to customized stylesheet_path" do
      Sprite.new('stylesheet_path' => 'public/stylesheets').build
    end

    it "should build css_sprite image and scss" do
      Sprite.new('engine' => 'scss', 'stylesheet_path' => 'public/stylesheets').build
    end
  end

  describe "css_sprite_directories" do
    it "should read two direcoties" do
      expect(@sprite.css_sprite_directories.size).to eq 2
      expect(@sprite.css_sprite_directories).to be_include File.join(IMAGE_PATH, 'another_css_sprite')
      expect(@sprite.css_sprite_directories).to be_include File.join(IMAGE_PATH, 'css_sprite')
    end
  end

  describe "output_image" do
    it "should output a css_sprite image for a directory" do
      @sprite.output_image(File.join(IMAGE_PATH, 'css_sprite'))
    end
  end

  describe "all_images" do
    it "should read all images from a directory" do
      expected_images = [File.join(IMAGE_PATH, 'css_sprite/icons/twitter_icon.png'),
                         File.join(IMAGE_PATH, 'css_sprite/icons/twitter_icon_hover.png'),
                         File.join(IMAGE_PATH, 'css_sprite/icons/facebook_icon.png'),
                         File.join(IMAGE_PATH, 'css_sprite/icons/facebook_icon_hover.png'),
                         File.join(IMAGE_PATH, 'css_sprite/hotmail_logo.png'),
                         File.join(IMAGE_PATH, 'css_sprite/gmail_logo.png'),
                         File.join(IMAGE_PATH, 'css_sprite/gmail_logo_active.png'),
                         File.join(IMAGE_PATH, 'css_sprite/logos_hover/gmail_logo.png'),
                         File.join(IMAGE_PATH, 'css_sprite/logos/gmail_logo.png'),
                         File.join(IMAGE_PATH, 'css_sprite/logos/gmail_logo_active.png')]
      actual_images = @sprite.all_images(File.join(IMAGE_PATH, 'css_sprite'))
      expect(actual_images.size).to eq expected_images.size
      expected_images.each do |expected_image|
        expect(actual_images).to be_include(expected_image)
      end
    end
  end

  describe "class_names" do
    before(:context) do
      @results = [{:name => 'gmail_logo'}, {:name => 'hotmail_logo'}, {:name => 'yahoo_logo'},
                 {:name => 'gmail_button'}, {:name => 'hotmail_button'}, {:name => 'yahoo_button'}]
    end

    it "should get class_names with default options" do
      expect(@sprite.class_names(@results)).to eq [".gmail_logo, .hotmail_logo, .yahoo_logo, .gmail_button, .hotmail_button", ".yahoo_button"]
    end

    it "should get class_names with 3 count_per_line" do
      expect(@sprite.class_names(@results, :count_per_line => 3)).to eq [".gmail_logo, .hotmail_logo, .yahoo_logo", ".gmail_button, .hotmail_button, .yahoo_button"]
    end

    it "should get specified class_names with suffix" do
      expect(@sprite.class_names(@results, :suffix => 'logo')).to eq [".gmail_logo, .hotmail_logo, .yahoo_logo"]
    end
  end

  describe "class_name" do
    it "should get class_name with simple name" do
      expect(@sprite.class_name("twitter_icon")).to eq ".twitter_icon"
    end

    it "should get class_name with parent class" do
      expect(@sprite.class_name("icons/twitter_icon")).to eq ".icons .twitter_icon"
    end

    it "should get class_name with hover class" do
      expect(@sprite.class_name("icons/twitter_icon_hover")).to eq ".icons .twitter_icon:hover"
      expect(@sprite.class_name("icons/twitter-icon-hover")).to eq ".icons .twitter-icon:hover"
      expect(@sprite.class_name("twitter_hover_icon")).to eq ".twitter_hover_icon"
      expect(@sprite.class_name("twitter_hover_icon_hover")).to eq ".twitter_hover_icon:hover"
      expect(@sprite.class_name("logos_hover/gmail_logo")).to eq ".logos:hover .gmail_logo"
    end

    it "should get class_name with active class" do
      expect(@sprite.class_name("gmail_logo_active")).to eq ".gmail_logo.active"
      expect(@sprite.class_name("logos_active/gmail_logo")).to eq ".logos.active .gmail_logo"
      expect(@sprite.class_name("logos/gmail_logo_active")).to eq ".logos .gmail_logo.active"
    end
  end

  describe "dest_image_path" do
    it "should get css_sprite image path for a directory" do
      expect(@sprite.dest_image_path(File.join(IMAGE_PATH, 'css_sprite'))).to eq File.join(IMAGE_PATH, 'css_sprite.png')
    end
  end

  describe "dest_image_name" do
    it "should get css_sprite image name for a directory" do
      expect(@sprite.dest_image_name(File.join(IMAGE_PATH, 'css_sprite'))).to eq 'css_sprite.png'
    end
  end

  describe "dest_stylesheet_path for css" do
    it "should get css_sprite css path for a directory" do
      expect(Sprite.new("engine" => "css").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite'))).to eq File.join(STYLESHEET_PATH, 'css_sprite.css')
    end
  end

  describe "dest_stylesheet_path for sass" do
    it "should get sass_sprite css path for a directory" do
      expect(Sprite.new("engine" => "sass").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite'))).to eq File.join(STYLESHEET_PATH, 'css_sprite.sass')
    end
  end

  describe "dest_stylesheet_path for scss" do
    it "should get sass_sprite css path for a directory" do
      expect(Sprite.new("engine" => "scss").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite'))).to eq File.join(STYLESHEET_PATH, 'css_sprite.scss')
    end
  end

  describe "get_image" do
    it "should get a image" do
      expect(@sprite.get_image(File.join(IMAGE_PATH, 'css_sprite/gmail_logo.png')).class).to eq MiniMagick::Image
    end
  end

  describe "image_properties" do
    it "should get image properties" do
      image_path = File.join(@directory_path, 'gmail_logo.png')
      expect(@sprite.image_properties(image_path, @directory_path)).to eq({:name => 'gmail_logo', :width => 103, :height => 36})
    end

    it "should get a image with parent" do
      image_path = File.join(@directory_path, 'icons/twitter_icon.png')
      expect(@sprite.image_properties(image_path, @directory_path)).to eq({:name => 'icons/twitter_icon', :width => 14, :height => 14})
    end
  end
end
