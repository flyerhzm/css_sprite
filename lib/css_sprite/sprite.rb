require 'find'
require 'RMagick'
require 'yaml'
require 'enumerator'

class Sprite

  def initialize(options={})
    if File.exist?(File.join(Rails.root, 'config/css_sprite.yml'))
      @config = YAML::load_file(File.join(Rails.root, 'config/css_sprite.yml'))
    else
      @config = options
    end

    @image_path = File.expand_path(File.join(Rails.root, @config['image_path'] || 'public/images'))
    @stylesheet_path = File.expand_path(File.join(Rails.root, @config['stylesheet_path'] || 'public/stylesheets'))

    @css_images_path = @config['css_images_path'] ||= "images"
    @format = @config['format'] ? @config['format'].downcase : "png"
    @engine = @config['engine'] || "css"
  end

  # execute the css sprite operation
  def build
    directories = css_sprite_directories
    directories.each { |directory| execute(directory) }
  end

  # execute the css sprite operation if stylesheet is expired
  def check
    directories = css_sprite_directories
    directories.each { |directory| execute(directory) if expire?(directory) }
  end

  # output the css sprite image and stylesheet
  def execute(directory)
    results = output_image(directory)
    unless results.empty?
      optimize_image(directory)
      output_stylesheet(directory, results)
    end
  end

  # detect if the stylesheet is expired or not?
  def expire?(directory)
    stylesheet_path = dest_stylesheet_path(directory)
    return true unless File.exist?(stylesheet_path)
    stylesheet_mtime = File.new(stylesheet_path).mtime
    Dir["**/*"].each do |path|
      return true if path !~ /.*\..*/ and File.new(path).mtime > stylesheet_mtime
    end
    return false
  end

  # output stylesheet, sass, scss or css
  def output_stylesheet(directory, results)
    if sass?
      output_sass(directory, results)
    elsif scss?
      output_scss(directory, results)
    else
      output_css(directory, results)
    end
  end

  # use sass
  def sass?
    @engine =~ /sass$/
  end

  # use scss
  def scss?
    @engine =~ /scss$/
  end

  # detect all the css sprite directories. e.g. public/images/css_sprite, public/images/widget_css_sprite
  def css_sprite_directories
    Dir.entries(@image_path).collect do |d|
      File.join(@image_path, d) if File.directory?(File.join(@image_path, d)) and d =~ /css_sprite$/
    end.compact
  end

  # output the css sprite image and return all the images properies.
  def output_image(directory)
    results = []
    sources = all_images(directory)
    dest_image_path = dest_image_path(directory)
    span = 5
    unless sources.empty?
      dest_image = get_image(sources.shift)
      results << image_properties(dest_image, directory).merge(:x => 0, :y => 0)
      sources.each do |source|
        source_image = get_image(source)
        gravity = Magick::SouthGravity
        x = 0
        y = dest_image.rows + span
        results << image_properties(source_image, directory).merge(:x => x, :y => y)
        dest_image = composite_images(dest_image, source_image, x, y)
      end
      dest_image.image_type = @config['image_type'] ? Magick.const_get(@config['image_type']) : Magick::PaletteMatteType
      dest_image.format = @config['format'] || "PNG"
      dest_image.write(dest_image_path)
    end
    results
  end

  # opitmize the css sprite image
  def optimize_image(directory)
    unless @config['disable_optimization']
      dest_image_path = dest_image_path(directory)
      command  = @config['optimization'] ? "#{@config['optimization']} #{dest_image_path}" : "optipng -quiet #{dest_image_path}"
      result = system(command)
      puts %Q(Optimization command "#{command}" execute failed) unless result
    end
  end

  # output the css sprite css
  def output_css(directory, results)
    unless results.empty?
      dest_image_name = dest_image_name(directory)
      dest_stylesheet_path = dest_stylesheet_path(directory)
      dest_image_time = File.new(dest_image_path(directory)).mtime
      File.open(dest_stylesheet_path, 'w') do |f|
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
        f.print " \{\n  background: url('/#{@css_images_path}/#{dest_image_name}?#{dest_image_time.to_i}') no-repeat;\n\}\n"

        results.each do |result|
          f.print "#{class_name(result[:name])} \{"
          f.print " background-position: #{-result[:x]}px #{-result[:y]}px;"
          f.print " width: #{result[:width]}px;" if result[:width]
          f.print " height: #{result[:height]}px;" if result[:height]
          f.print " \}\n"
        end
      end
    end
  end

  # output the css sprite sass file
  def output_sass(directory, results)
    unless results.empty?
      dest_image_name = dest_image_name(directory)
      dest_stylesheet_path = dest_stylesheet_path(directory)
      dest_image_time = File.new(dest_image_path(directory)).mtime
      File.open(dest_stylesheet_path, 'w') do |f|
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
        if @config['use_asset_url']
          f.print " \n  background: asset-url('#{dest_image_name}', image) no-repeat\n"
        else
          f.print " \n  background: url('/#{@css_images_path}/#{dest_image_name}?#{dest_image_time.to_i}') no-repeat\n"
        end

        results.each do |result|
          f.print "#{class_name(result[:name])}\n"
          f.print "  background-position: #{-result[:x]}px #{-result[:y]}px\n"
          f.print "  width: #{result[:width]}px\n" if result[:width]
          f.print "  height: #{result[:height]}px\n" if result[:height]
        end
      end
    end
  end

  # output the css sprite scss file
  def output_scss(directory, results)
    unless results.empty?
      dest_image_name = dest_image_name(directory)
      dest_stylesheet_path = dest_stylesheet_path(directory)
      dest_image_time = File.new(dest_image_path(directory)).mtime
      File.open(dest_stylesheet_path, 'w') do |f|
        if @config['suffix']
          @config['suffix'].each do |key, value|
            cns = class_names(results, :suffix => key)
            unless cns.empty?
              f.print cns.join(",\n")
              f.print "\{\n"
              f.print value.split("\n").collect { |text| "  " + text }.join("\n")
              f.print "\}\n"
            end
          end
        end

        f.print class_names(results).join(",\n")
        if @config['use_asset_url']
          f.print " \{\n  background: asset-url('#{dest_image_name}', image) no-repeat;\n\}\n"
        else
          f.print " \{\n  background: url('/#{@css_images_path}/#{dest_image_name}?#{dest_image_time.to_i}') no-repeat;\n\}\n"
        end

        results.each do |result|
          f.print "#{class_name(result[:name])} \{\n"
          f.print "  background-position: #{-result[:x]}px #{-result[:y]}px;\n"
          f.print "  width: #{result[:width]}px;\n" if result[:width]
          f.print "  height: #{result[:height]}px;\n" if result[:height]
          f.print " \}\n"
        end
      end
    end
  end

  # get all the class names within the same css sprite image
  def class_names(results, options={})
    options = {:count_per_line => 5}.merge(options)
    class_names = []
    results = results.select { |result| result[:name] =~ %r|#{options[:suffix]}$| } if options[:suffix]
    results.each_slice(options[:count_per_line]) do |batch_results|
      class_names << batch_results.collect { |result| class_name(result[:name]) }.join(', ')
    end
    class_names
  end

  # get the css class name from image name
  def class_name(name)
    ".#{name.gsub('/', ' .').gsub(/[_-]hover\b/, ':hover').gsub(/[_-]active\b/, '.active')}"
  end

  # read all images under the css sprite directory
  def all_images(directory)
    images = []
    Find.find(directory) do |path|
      if path =~ /\.(png|gif|jpg|jpeg)$/
        images << path
      end
    end
    images
  end

  # destination css sprite image path
  def dest_image_path(directory)
    directory + "." + @format
  end

  # destination css sprite image name
  def dest_image_name(directory)
    File.basename(directory) + "." + @format
  end

  # destination stylesheet file path
  def dest_stylesheet_path(directory)
    File.join(@stylesheet_path, File.basename(directory) + "." + @engine)
  end

  # append src_image to the dest_image with position (x, y)
  def composite_images(dest_image, src_image, x, y)
    width = [src_image.columns + x, dest_image.columns].max
    height = [src_image.rows + y, dest_image.rows].max
    image = Magick::Image.new(width, height) {self.background_color = 'none'}
    image.composite!(dest_image, 0, 0, Magick::CopyCompositeOp)
    image.composite!(src_image, x, y, Magick::CopyCompositeOp)
    image
  end

  # get the Magick::Image
  def get_image(image_filename)
    Magick::Image::read(image_filename).first
  end

  # get image properties, including name, width and height
  def image_properties(image, directory)
    name = get_image_name(image, directory)
    need_wh?(image, directory) ? {:name => name, :width => image.columns, :height => image.rows} : {:name => name}
  end

  # check if the hover class needs width and height
  # if the hover class has the same width and height property with not hover class,
  # then the hover class does not need width and height
  def need_wh?(image, directory)
    name = get_image_name(image, directory)
    if hover?(name) or active?(name)
      not_file = image.filename.sub(/[_-](hover|active)\./, '.').sub(/[_-](hover|active)\//, '/')
      if File.exist?(not_file)
        not_image = get_image(not_file)
        return false if image.columns == not_image.columns and image.rows == not_image.rows
      end
    end
    return true
  end

  # get the image name substracting base directory and extname
  def get_image_name(image, directory)
    directory_length = directory.length + 1
    extname_length = File.extname(image.filename).length
    image.filename.slice(directory_length...-extname_length)
  end

  # test if the filename contains a hover or active.
  # e.g. icons/twitter_hover, icons_hover/twitter
  # e.g. icons/twitter_active, icons_active/twitter
  [:active, :hover].each do |method|
    class_eval <<-EOF
      def #{method}?(name)
        name =~ /[_-]#{method}$|[_-]#{method}\\//
      end
    EOF
  end

end
