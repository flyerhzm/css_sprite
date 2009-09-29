require 'RMagick'

class Sprite  
  CONFIG_PATH = RAILS_ROOT + '/config/'
  IMAGE_PATH = RAILS_ROOT + '/public/images/'
  TEMP_PATH = RAILS_ROOT + '/tmp/'
  
  def initialize
    @output = {}
  end
  
  def build
    sprite_config = File.open(CONFIG_PATH + 'css_sprite.yml') {|f| YAML::load(f)}
    sprite_config.each do |dest, configs|
      output_image(dest, configs)
    end
    
    output_css
  end
  
  def output_image(dest, configs)
    results = []
    sources = configs['sources'].collect {|source| Dir.glob(IMAGE_PATH + source)}.flatten
    span = configs['span'] || 0
    dest_image = get_image(sources.shift)
    results << image_properties(dest_image).merge(:x => 0, :y => 0)
    sources.each do |source|
      source_image = get_image(source)
      if configs['orient'] == 'horizontal'
        gravity = Magick::EastGravity
        x = dest_image.columns + span
        y = 0
      else
        gravity = Magick::SouthGravity
        x = 0
        y = dest_image.rows + span
      end
      results << image_properties(source_image).merge(:x => x, :y => y)
      dest_image = composite_images(dest_image, source_image, x, y)
    end
    @output[dest] = results
    dest_image.write(IMAGE_PATH + dest)
  end
  
  def output_css
    File.open(TEMP_PATH + 'css_sprite.css', 'w') do |f|
      @output.each do |dest, results|
        results.each do |result|
          f.puts ".#{result[:name]}"
          f.puts "\tbackgound: url('/images/#{dest}') no-repeat #{result[:x]}px #{result[:y]}px"
          f.puts "\twidth: #{result[:width]}px"
          f.puts "\theight: #{result[:height]}px"
          f.puts ""
        end
      end
    end
  end
  
  def composite_images(dest_image, src_image, x, y)
    width = [src_image.columns + x, dest_image.columns].max
    height = [src_image.rows + y, dest_image.rows].max
    image = Magick::Image.new(width, height)
    image.composite!(dest_image, 0, 0, Magick::AddCompositeOp)
    image.composite!(src_image, x, y, Magick::AddCompositeOp)
    image
  end
  
  def get_image(image_filename)
    image = Magick::Image::read(image_filename).first
  end
  
  def image_properties(image)
    {:name => File.basename(image.filename).split('.')[0], :width => image.columns, :height => image.rows}
  end
    
end
