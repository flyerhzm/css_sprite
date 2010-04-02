require 'find'
require 'RMagick'
require 'yaml'
require 'enumerator'

class Sprite
  
  def initialize(options={})
    @image_path = File.join(Rails.root, 'public/images')
    @stylesheet_path = File.join(Rails.root, 'public/stylesheets')
    @todo = {}
    
    if File.exist?(File.join(Rails.root, 'config/css_sprite.yml'))
      @config = YAML::load_file(File.join(Rails.root, 'config/css_sprite.yml'))
    else
      @config = options
    end
  end
  
  def build
    directories = css_sprite_directories
    directories.each { |directory| output_image(directory) }
    output_stylesheet
  end
  
  def check
    directories = css_sprite_directories
    directories.each do |directory|
      if expire?(directory)
        output_image(directory)
      end
    end
    output_stylesheet
  end
  
  def expire?(directory)
    if sass?
      stylesheet_path = dest_sass_path(directory)
    else
      stylesheet_path = dest_css_path(directory)
    end
    !File.exist?(stylesheet_path) or File.new(directory).mtime > File.new(stylesheet_path).mtime
  end
  
  def output_stylesheet
    if sass?
      output_sass
    else
      output_css
    end
  end
  
  def sass?
    @config['engine'] == 'sass'
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
      dest_image.image_type = Magick::PaletteMatteType
      dest_image.write(dest_image_path)
    end
    @todo[directory] = results
  end

  def output_css
    @todo.each do |directory, results|
      unless results.empty?
        dest_image_name = dest_image_name(directory)
        dest_css_path = dest_css_path(directory)
        File.open(dest_css_path, 'w') do |f|
          if @config['suffix']
            @config['suffix'].each do |key, value|
              cns = class_names(results, :suffix => key)
              unless cns.empty?
                f.print cns.join(",\n")
                f.print " \{\n"
                f.print value.split("\n").collect { |text| "  " + text }.join("\n")
                f.print "\}\n"
              end
            end
          end
          
          f.print class_names(results).join(",\n")
          f.print " \{\n  background: url('/images/#{dest_image_name}?#{Time.now.to_i}') no-repeat;\n\}\n"
        
          results.each do |result|
            f.print ".#{result[:name]} \{"
            f.print " background-position: #{-result[:x]}px #{-result[:y]}px;"
            f.print " width: #{result[:width]}px;"
            f.print " height: #{result[:height]}px;"
            f.print " \}\n"
          end
        end
      end
    end
  end
  
  def output_sass
    @todo.each do |directory, results|
      unless results.empty?
        dest_image_name = dest_image_name(directory)
        dest_sass_path = dest_sass_path(directory)
        File.open(dest_sass_path, 'w') do |f|
          if @config['suffix']
            @config['suffix'].each do |key, value|
              cns = class_names(results, :suffix => key)
              unless cns.empty?
                f.print cns.join(",\n")
                f.print "\n"
                f.print value.split("\n").collect { |text| "  " + text }.join("\n")
                f.print "\n"
              end
            end
          end
          
          f.print class_names(results).join(",\n")
          f.print " \n  background: url('/images/#{dest_image_name}?#{Time.now.to_i}') no-repeat\n"
        
          results.each do |result|
            f.print ".#{result[:name]}\n"
            f.print "  background-position: #{-result[:x]}px #{-result[:y]}px\n"
            f.print "  width: #{result[:width]}px\n"
            f.print "  height: #{result[:height]}px\n"
          end
        end
      end
    end
  end
  
  def class_names(results, options={})
    options = {:count_per_line => 5}.merge(options)
    class_names = []
    results = results.select { |result| result[:name] =~ %r|#{options[:suffix]}$| } if options[:suffix]
    results.each_slice(options[:count_per_line]) do |batch_results|
      class_names << batch_results.collect { |result| ".#{result[:name]}" }.join(', ')
    end
    class_names
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

  def dest_sass_path(directory)
    File.join(@stylesheet_path, 'sass', File.basename(directory) + '.sass')
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
