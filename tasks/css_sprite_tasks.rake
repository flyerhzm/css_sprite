namespace :css_sprite do  
  desc "build css sprite image once"
  task :build do
    require File.join(File.dirname(__FILE__), '../lib/css_sprite/sprite.rb')
    Sprite.new.build
  end
  
  desc "start css sprite server"
  task :start do
    if RUBY_PLATFORM.include?('mswin32')
      exec "start "
      puts "css_sprite server started sucessfully."
    else
      file_path = "#{Rails.root}/tmp/pids/css_sprite.pid"
      if File.exists?(file_path)
        puts "css_sprite server is started. I haven't done anything."
      else
        pid = fork do
          automatic_script = File.join(File.dirname(__FILE__), '..', 'lib', 'automatic.rb')
          exec "ruby #{automatic_script}"
        end
      
        sleep(1)
        File.open("#{Rails.root}/tmp/pids/css_sprite.pid", "w") { |f| f << pid }
        puts "css_sprite server started sucessfully."
      end
    end
  end
  
  desc "stop css sprite server"
  task :stop do
    if RUBY_PLATFORM.include?('mswin32')
      exec "taskkill "
      puts "css_sprite server shutdown sucessfully."
    else
      file_path = "#{Rails.root}/tmp/pids/css_sprite.pid"
      if File.exists?(file_path)
        fork do
          File.open(file_path, "r") do |f|
           pid = f.readline
           Process.kill('TERM', pid.to_i)
          end
        end

        Process.wait
        File.unlink(file_path)
        puts "css_sprite server shutdown sucessfully."
      else
        puts "css_sprite server is not running. I haven't done anything."
      end
    end
  end
  
end
