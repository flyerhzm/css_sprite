require 'RMagick'

class Sprite  
  CONFIG_PATH = RAILS_ROOT + '/config/'
  IMAGE_PATH = RAILS_ROOT + '/public/images/'
  PUBLIC_PATH = RAILS_ROOT + '/public/stylesheets/'
  
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
    results << image_properties(dest_image).merge(:x => 0, :y => 0, :prefix => configs['prefix'])
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
      results << image_properties(source_image).merge(:x => x, :y => y, :prefix => configs['prefix'])
      dest_image = composite_images(dest_image, source_image, x, y)
    end
    @output[dest] = results
    dest_image.write(IMAGE_PATH + dest)
  end
  
  def output_css
    File.open(PUBLIC_PATH + 'css_sprite.css', 'w') do |f|
      f.puts "/* do not touch - generated through 'rake css_sprite:build' */"
      @output.each do |dest, results|
        basename = File.basename(dest, File.extname(dest))
        f.puts ".#{results.first[:prefix]}#{basename} { background: url('/images/#{dest}?#{Time.now.to_i}') no-repeat; }"
        results.each do |result|
          f.print ".#{result[:prefix]}#{result[:name]} \{ "
          f.print "background-position: #{result[:x]}px #{result[:y]}px;"
          f.print "width: #{result[:width]}px;"
          f.print "height: #{result[:height]}px;"
          f.print "\}\n"
        end
      end
    end
  end
  
  def composite_images(dest_image, src_image, x, y)
    width = [src_image.columns + x, dest_image.columns].max
    height = [src_image.rows + y, dest_image.rows].max
    image = Magick::Image.new(width, height) {self.background_color = 'none'}
    image.composite!(dest_image, 0, 0, Magick::CopyCompositeOp)
    image.composite!(src_image, x, y, Magick::CopyCompositeOp)
    image
  end
  
  def get_image(image_filename)
    image = Magick::Image::read(image_filename).first
  end
  
  def image_properties(image)
    {:name => File.basename(image.filename).split('.')[0], :width => image.columns, :height => image.rows}
  end
    
end
