require 'RMagick'
require 'find'

class Sprite
  
  def initialize
    @image_path = File.join(Rails.root, 'public/images')
    @stylesheet_path = File.join(Rails.root, 'public/stylesheets')
    @todo = {}
  end
  
  def build
    directories = css_sprite_directories
    directories.each { |directory| output_image(directory) }
    output_css
  end
  
  def css_sprite_directories
    Dir.entries(@image_path).collect do |d|
      File.join(@image_path, d) if File.directory?(File.join(@image_path, d)) and d =~ /css_sprite$/
    end.compact
  end
  
  def output_image(directory)
    results = []
    sources = all_images(directory)
    dest_image_path = dest_image_path(directory)
    span = 5
    unless sources.empty?
      dest_image = get_image(sources.shift)
      results << image_properties(dest_image).merge(:x => 0, :y => 0)
      sources.each do |source|
        source_image = get_image(source)
        gravity = Magick::SouthGravity
        x = 0
        y = dest_image.rows + span
        results << image_properties(source_image).merge(:x => x, :y => y)
        dest_image = composite_images(dest_image, source_image, x, y)
      end
      dest_image.write(dest_image_path)
    end
    @todo[directory] = results
  end

  def output_css
    @todo.each do |directory, results|
      dest_image_name = dest_image_name(directory)
      dest_css_path = dest_css_path(directory)
      File.open(dest_css_path, 'w') do |f|
        results.each do |result|
          f.print ".#{result[:name]} \{"
          f.print " background: url('/images/#{dest_image_name}?#{Time.now.to_i}') no-repeat;"
          f.print " background-position: #{-result[:x]}px #{-result[:y]}px;"
          f.print " width: #{result[:width]}px;"
          f.print " height: #{result[:height]}px;"
          f.print " \}\n"
        end
      end
    end
  end
  
  def all_images(directory)
    images = []
    Find.find(directory) do |path|
      if path =~ /\.(png|gif|jpg|jpeg)$/
        images << path
      end
    end
    images
  end
  
  def dest_image_path(directory)
    directory + ".png"
  end
  
  def dest_image_name(directory)
    File.basename(directory) + ".png"
  end
  
  def dest_css_path(directory)
    File.join(@stylesheet_path, File.basename(directory) + '.css')
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
    Magick::Image::read(image_filename).first
  end
  
  def image_properties(image)
    {:name => File.basename(image.filename, File.extname(image.filename)), :width => image.columns, :height => image.rows}
  end
    
end
