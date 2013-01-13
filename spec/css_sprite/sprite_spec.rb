require 'spec_helper'

describe Sprite do
  before(:all) do
    @sprite = Sprite.new
    @directory_path = File.join(IMAGE_PATH, 'css_sprite')
  end

  describe "build" do
    it "should build css_sprite image and css" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new.build
    end

    it "should build css_sprite image and sass" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('engine' => 'sass').build
    end

    it "should build another image_type" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('image_type' => 'PaletteType').build
    end

    it "should disable image optimization" do
      Sprite.new('disable_optimization' => true).build
    end

    it "should build another image optimization" do
      Sprite.any_instance.expects(:system).with("optipng -o 1 #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('optimization' => "optipng -o 1").build
    end

    it "should output css to customized stylesheet_path" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('stylesheet_path' => 'public/stylesheets').build
    end

    it "should build css_sprite image and scss" do
      Sprite.any_instance.expects(:system).with("optipng -quiet #{IMAGE_PATH}/css_sprite.png").returns(true)
      Sprite.new('engine' => 'scss', 'stylesheet_path' => 'public/stylesheets').build
    end
  end

  describe "css_sprite_directories" do
    it "should read two direcoties" do
      expected_directories = [File.join(IMAGE_PATH, 'another_css_sprite'),
                                  File.join(IMAGE_PATH, 'css_sprite')]
      @sprite.css_sprite_directories.should == expected_directories
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
      actual_images.size.should == expected_images.size
      expected_images.each do |expected_image|
        actual_images.should be_include(expected_image)
      end
    end
  end

  describe "class_names" do
    before(:all) do
      @results = [{:name => 'gmail_logo'}, {:name => 'hotmail_logo'}, {:name => 'yahoo_logo'},
                 {:name => 'gmail_button'}, {:name => 'hotmail_button'}, {:name => 'yahoo_button'}]
    end

    it "should get class_names with default options" do
      @sprite.class_names(@results).should == [".gmail_logo, .hotmail_logo, .yahoo_logo, .gmail_button, .hotmail_button", ".yahoo_button"]
    end

    it "should get class_names with 3 count_per_line" do
      @sprite.class_names(@results, :count_per_line => 3).should == [".gmail_logo, .hotmail_logo, .yahoo_logo", ".gmail_button, .hotmail_button, .yahoo_button"]
    end

    it "should get specified class_names with suffix" do
      @sprite.class_names(@results, :suffix => 'logo').should == [".gmail_logo, .hotmail_logo, .yahoo_logo"]
    end
  end

  describe "class_name" do
    it "should get class_name with simple name" do
      @sprite.class_name("twitter_icon").should == ".twitter_icon"
    end

    it "should get class_name with parent class" do
      @sprite.class_name("icons/twitter_icon").should == ".icons .twitter_icon"
    end

    it "should get class_name with hover class" do
      @sprite.class_name("icons/twitter_icon_hover").should == ".icons .twitter_icon:hover"
      @sprite.class_name("icons/twitter-icon-hover").should == ".icons .twitter-icon:hover"
      @sprite.class_name("twitter_hover_icon").should == ".twitter_hover_icon"
      @sprite.class_name("twitter_hover_icon_hover").should == ".twitter_hover_icon:hover"
      @sprite.class_name("logos_hover/gmail_logo").should == ".logos:hover .gmail_logo"
    end

    it "should get class_name with active class" do
      @sprite.class_name("gmail_logo_active").should == ".gmail_logo.active"
      @sprite.class_name("logos_active/gmail_logo").should == ".logos.active .gmail_logo"
      @sprite.class_name("logos/gmail_logo_active").should == ".logos .gmail_logo.active"
    end
  end

  describe "dest_image_path" do
    it "should get css_sprite image path for a directory" do
      @sprite.dest_image_path(File.join(IMAGE_PATH, 'css_sprite')).should == File.join(IMAGE_PATH, 'css_sprite.png')
    end
  end

  describe "dest_image_name" do
    it "should get css_sprite image name for a directory" do
      @sprite.dest_image_name(File.join(IMAGE_PATH, 'css_sprite')).should == 'css_sprite.png'
    end
  end

  describe "dest_stylesheet_path for css" do
    it "should get css_sprite css path for a directory" do
      Sprite.new("engine" => "css").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite')).should == File.join(STYLESHEET_PATH, 'css_sprite.css')
    end
  end

  describe "dest_stylesheet_path for sass" do
    it "should get sass_sprite css path for a directory" do
      Sprite.new("engine" => "sass").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite')).should == File.join(STYLESHEET_PATH, 'css_sprite.sass')
    end
  end

  describe "dest_stylesheet_path for scss" do
    it "should get sass_sprite css path for a directory" do
      Sprite.new("engine" => "scss").dest_stylesheet_path(File.join(IMAGE_PATH, 'css_sprite')).should == File.join(STYLESHEET_PATH, 'css_sprite.scss')
    end
  end

  describe "get_image" do
    it "should get a image" do
      @sprite.get_image(File.join(IMAGE_PATH, 'css_sprite/gmail_logo.png')).class.should == MiniMagick::Image
    end
  end

  describe "image_properties" do
    it "should get image properties" do
      image_path = File.join(@directory_path, 'gmail_logo.png')
      @sprite.image_properties(image_path, @directory_path).should == {:name => 'gmail_logo', :width => 103, :height => 36}
    end

    it "should get a image with parent" do
      image_path = File.join(@directory_path, 'icons/twitter_icon.png')
      @sprite.image_properties(image_path, @directory_path).should == {:name => 'icons/twitter_icon', :width => 14, :height => 14}
    end
  end
end
