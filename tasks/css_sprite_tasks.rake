require 'rbconfig'

namespace :css_sprite do
  desc "build css sprite image once"
  task :build do
    require File.join(File.dirname(__FILE__), '../lib/css_sprite/sprite.rb')
    Sprite.new.build
  end

  desc "restart css sprite server"
  task :restart => [:stop, :start]

  desc "start css sprite server"
  task :start do
    automatic_script = File.join(File.dirname(__FILE__), '..', 'lib', 'automatic.rb')
    if Config::CONFIG['host_os'] =~ /mswin|mingw/
      exec "start \"css_sprite\" ruby.exe #{automatic_script}"
      puts "css_sprite server started sucessfully."
    else
      file_path = "#{Rails.root}/tmp/pids/css_sprite.pid"
      if File.exists?(file_path)
        puts "css_sprite server is started. I haven't done anything. Please use rake css_sprite:restart instead."
      else
        pid = fork do
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
    if Config::CONFIG['host_os'] =~ /mswin|mingw/
      exec "taskkill /im ruby.exe /fi \"Windowtitle eq css_sprite\""
      puts "css_sprite server shutdown sucessfully."
    else
      file_path = "#{Rails.root}/tmp/pids/css_sprite.pid"
      if File.exists?(file_path)
        fork do
          File.open(file_path, "r") do |f|
            pid = f.readline
            begin
              Process.kill('TERM', pid.to_i)
            rescue Errno::ESRCH
            end
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
