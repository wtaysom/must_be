require 'rubygems'
require 'rake'
require 'echoe'

ENV['MUST_BE__NOTIFIER'] = "disable"
require 'lib/must_be'

Echoe.new('must_be', MustBe::VERSION) do |p|
  p.description = "MustBe Runtime Assertions"
  p.url = "http://github.com/#?{Where we want to put it.}"
  p.author = "William Taysom"
  p.email = "wtaysom@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = []
end

desc "Run the spec suite against rcov"
Spec::Rake::SpecTask.new('spec_cov_helper') do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', '/Library/Ruby/Gems/']
end

desc "Run the spec suite against rcov and open conerage results"
task :spec_cov => :spec_cov_helper do
  `open coverage/index.html`
end