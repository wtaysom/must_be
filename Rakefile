require 'rspec/core/rake_task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "must_be"
    gemspec.summary = "must_be Runtime Assertions"
    gemspec.description = "must_be provides runtime assertions which can easily be disabled in production environments.  Likewise, the notifier can be customized to raise errors, log failure, enter the debugger, or anything else."
    gemspec.email = "wtaysom@gmail.com"
    gemspec.homepage = "http://github.com/wtaysom/must_be"
    gemspec.authors = ["William Taysom"]
    
    gemspec.add_development_dependency('jeweler', '~> 1.4')
    gemspec.add_development_dependency('rspec', '~> 2.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Run the spec suite against rcov"
RSpec::Core::RakeTask.new(:rcov_helper) do |t|
  t.rcov = true
  t.rcov_opts = %q{--exclude "gems/,spec/"}
end

desc "Run the spec suite against rcov and open coverage results"
task :rcov => :rcov_helper do
  `open coverage/index.html`
end