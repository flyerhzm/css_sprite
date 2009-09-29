require File.dirname(__FILE__) + '/spec_helper'

describe CssSprite do
  before(:all) do
    @sprite = CssSprite.new
  end
  
  context "get_image" do
    it "should get a image" do
      @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/good_topic.gif')).class.should == Magick::Image
    end
  end
  
  context "image_properties" do
    it "should get image properties" do
      image = @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/good_topic.gif'))
      @sprite.image_properties(image).should == {:name => 'good_topic', :width => 20, :height => 19}
    end
  end
  
  context "composite_images" do
    it "should composite two images into one horizontally" do
      image1 = @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/good_topic.gif'))
      image2 = @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/mid_topic.gif'))
      image = @sprite.composite_images(image1, image2, image1.columns, 0)
      @sprite.image_properties(image).should == {:name => nil, :width => 40, :height => 19}
    end
    
    it "should composite two images into one verically" do
      image1 = @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/good_topic.gif'))
      image2 = @sprite.get_image(File.join(File.dirname(__FILE__), 'resources/mid_topic.gif'))
      image = @sprite.composite_images(image1, image2, 0, image1.rows)
      @sprite.image_properties(image).should == {:name => nil, :width => 20, :height => 38}
    end
  end
end