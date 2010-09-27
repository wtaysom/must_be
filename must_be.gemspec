# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{must_be}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["William Taysom"]
  s.date = %q{2010-09-27}
  s.description = %q{must_be provides runtime assertions which can easily be disabled in production environments.  Likewise, the notifier can be customized to raise errors, log failure, enter the debugger, or anything else.}
  s.email = %q{wtaysom@gmail.com}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".gitignore",
     "README.md",
     "Rakefile",
     "VERSION",
     "doc/readme/examples.rb",
     "doc/readme/run_examples.rb",
     "lib/must_be.rb",
     "lib/must_be/attr_typed.rb",
     "lib/must_be/basic.rb",
     "lib/must_be/containers.rb",
     "lib/must_be/containers_registered_classes.rb",
     "lib/must_be/core.rb",
     "lib/must_be/nonstandard_control_flow.rb",
     "lib/must_be/proxy.rb",
     "must_be.gemspec",
     "spec/must_be/attr_typed_spec.rb",
     "spec/must_be/basic_spec.rb",
     "spec/must_be/containers_spec.rb",
     "spec/must_be/core_spec.rb",
     "spec/must_be/nonstandard_control_flow_spec.rb",
     "spec/must_be/proxy_spec.rb",
     "spec/notify_matcher_spec.rb",
     "spec/spec_helper.rb",
     "spec/typical_usage_spec.rb"
  ]
  s.homepage = %q{http://github.com/wtaysom/must_be}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{must_be Runtime Assertions}
  s.test_files = [
    "spec/must_be/attr_typed_spec.rb",
     "spec/must_be/basic_spec.rb",
     "spec/must_be/containers_spec.rb",
     "spec/must_be/core_spec.rb",
     "spec/must_be/nonstandard_control_flow_spec.rb",
     "spec/must_be/proxy_spec.rb",
     "spec/notify_matcher_spec.rb",
     "spec/spec_helper.rb",
     "spec/typical_usage_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

