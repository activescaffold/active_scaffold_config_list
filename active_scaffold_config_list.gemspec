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
  s.files = `git ls-files -- app config lib`.split("\n") + %w[LICENSE.txt README]
  s.extra_rdoc_files = [
    "README"
  ]
  s.licenses = ["MIT"]

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.add_runtime_dependency(%q<active_scaffold>, [">= 3.4.31"])
  s.add_runtime_dependency(%q<active_scaffold_sortable>, [">= 3.2.2"])
  s.add_runtime_dependency('rails', '>= 4.0')
end
