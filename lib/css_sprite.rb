require 'rake'

unless Rake::Task.task_defined? "css_sprite:build"
  load File.join(File.dirname(__FILE__), '..', 'tasks', 'css_sprite_tasks.rake')
end
