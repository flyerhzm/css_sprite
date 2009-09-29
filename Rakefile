require 'rake'
require 'spec/rake/spectask'
require 'jeweler'

desc 'Default: run unit tests.'
task :default => :spec

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "css_sprite"
  gemspec.summary = "css_sprite is a rails plugin/gem to generate css sprite image automatically."
  gemspec.description = "css_sprite is a rails plugin/gem to generate css sprite image automatically."
  gemspec.email = "flyerhzm@gmail.com"
  gemspec.homepage = "" 
  gemspec.authors = ["Richard Huang"]
  gemspec.files.exclude '.gitignore'
end

