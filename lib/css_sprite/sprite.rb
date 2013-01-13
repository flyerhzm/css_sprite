require 'find'
require 'mini_magick'
require 'yaml'
require 'enumerator'

class Sprite

  def initialize(options={})
    base_dir = Dir.pwd
    if File.exist?(File.join(base_dir, 'config/css_sprite.yml'))
      @config = YAML::load_file(File.join(base_dir, 'config/css_sprite.yml'))
    else
      @config = options
    end

    @image_path = File.expand_path(File.join(base_dir, @config['image_path'] || 'app/assets/images'))
    @stylesheet_path = File.expand_path(File.join(base_dir, @config['stylesheet_path'] || 'app/assets/stylesheets'))

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

  # detect all the css sprite directories. e.g. app/assets/images/css_sprite, app/assets/images/widget_css_sprite
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
    return results if sources.empty?
    last_y = 0
    sources.each do |source|
      source_image = get_image(source)
      property =
      x = 0
      y = last_y
      results << image_properties(source, directory).merge(:x => x, :y => y)
      last_y = y + source_image[:height]
    end

    command = MiniMagick::CommandBuilder.new('montage')
    sources.each do |source|
      command.push command.escape_string source
    end
    command.push('-tile 1x')
    command.push("-geometry +0+0")
    command.push('-background None')
    command.push('-gravity West')
    command.push('-format')
    format = @config['format'] || "PNG"
    command.push(command.escape_string(format))
    command.push(command.escape_string(dest_image_path))
    MiniMagick::Image.new(nil).run(command)
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

  # get the Magick::Image
  def get_image(image_filename)
    MiniMagick::Image.open(image_filename)
  end

  # get image properties, including name, width and height
  def image_properties(image_path, directory)
    name = get_image_name(image_path, directory)
    image = get_image(image_path)
    need_wh?(image_path, directory) ? {:name => name, :width => image[:width], :height => image[:height]} : {:name => name}
  end

  # check if the hover class needs width and height
  # if the hover class has the same width and height property with not hover class,
  # then the hover class does not need width and height
  def need_wh?(image_path, directory)
    name = get_image_name(image_path, directory)
    if hover?(name) or active?(name)
      not_file = image_path.sub(/[_-](hover|active)\./, '.').sub(/[_-](hover|active)\//, '/')
      if File.exist?(not_file)
        image = get_image(image_path)
        not_image = get_image(not_file)
        return false if image[:width] == not_image[:width] and image[:height] == not_image[:height]
      end
    end
    return true
  end

  # get the image name substracting base directory and extname
  def get_image_name(image_path, directory)
    extname_length = File.extname(image_path).length
    image_path.slice(directory.length+1...-extname_length)
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
