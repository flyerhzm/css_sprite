require 'rake'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :spec

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end
