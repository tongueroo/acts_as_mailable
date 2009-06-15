require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
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


GEM_NAME = 'acts_as_mailable'
PKG_FILES = FileList['**/*']

task :default => "gemspec"

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = "0.1.0"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.extra_rdoc_files = [ "README.markdown" ]
  s.summary = ""
  s.description = ""
  s.author = "Tung Nguyen"
  s.email = "tongueroo@gmail.com"
  s.homepage = "http://github.com/tongueroo/#{GEM_NAME}"

  s.require_path = "lib"
  s.files = PKG_FILES.to_a
end

desc "Install gem"
task :install do
  Rake::Task['gemspec'].invoke
  `gem build #{GEM_NAME}.gemspec`
  `sudo gem uninstall #{GEM_NAME} -x`
  `sudo gem install #{GEM_NAME}*.gem`
  `rm #{GEM_NAME}*.gem`
end

desc "Generate gemspec"
task :gemspec do
  File.open("#{File.dirname(__FILE__)}/#{GEM_NAME}.gemspec", 'w') do |f|
    f.write(spec.to_ruby)
  end
end

