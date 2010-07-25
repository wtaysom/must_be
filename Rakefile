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