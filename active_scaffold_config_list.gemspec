# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'active_scaffold_config_list/version'

Gem::Specification.new do |s|
  s.name = %q{active_scaffold_config_list}
  s.version = ActiveScaffoldConfigList::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = %q{activescaffold@googlegroups.com}
  s.authors = ["Sergio Cambra"]
  s.homepage = %q{http://activescaffold.com}
  s.summary = %q{User specific column configuration for ActiveScaffold}
  s.description = %q{User may reorder and hide/show list columns}
  s.require_paths = ["lib"]
  s.files = `git ls-files -- app config lib`.split("\n") + %w[LICENSE.txt README.md]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.required_ruby_version = '>= 2.5'
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.add_runtime_dependency(%q<active_scaffold>, [">= 3.7.1"]) # TODO require 4.3 when released, it will depend on changes added to framework-ui support
  s.add_runtime_dependency(%q<active_scaffold_sortable>, [">= 3.2.2"])
end
