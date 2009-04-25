require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Generate RDoc documentation for acts_as_mailable.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  files = ['README', '**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "acts_as_mailable"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
end


desc 'Run the specs'
Spec::Rake::SpecTask.new do |t|
  t.warning = false
  t.spec_opts = ["--color"]
end

