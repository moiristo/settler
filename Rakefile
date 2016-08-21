require 'rubygems'
require 'bundler/setup'
require 'appraisal'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "settler"
    gem.summary = %Q{Settler manages global application settings in Rails}
    gem.description = %Q{Settler can be used for defining application wide settings in Rails. Settings are loaded from a YAML file and stored in the database using ActiveRecord to allow users to update settings on the fly. The YAML configuration allows you to not only specify defaults, but setting value validations and typecasts as well!}
    gem.email = "r.j.delange@nedforce.nl"
    gem.homepage = "http://github.com/moiristo/settler"
    gem.authors = ["Reinier de Lange"]
    gem.license = "MIT"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "settler #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
