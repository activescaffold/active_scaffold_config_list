# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'active_scaffold_config_list/version'

Gem::Specification.new do |s|
  s.name = 'active_scaffold_config_list'
  s.version = ActiveScaffoldConfigList::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = 'activescaffold@googlegroups.com'
  s.authors = ['Sergio Cambra']
  s.homepage = 'http://activescaffold.com'
  s.summary = 'User specific column configuration for ActiveScaffold'
  s.description = 'User may reorder and hide/show list columns'
  s.require_paths = ['lib']
  s.files = `git ls-files -- app config lib`.split("\n") + %w[LICENSE.txt README.md]
  s.extra_rdoc_files = [
    'README.md'
  ]
  s.licenses = ['MIT']

  s.required_ruby_version = '>= 3.2'

  s.add_dependency('active_scaffold', ['>= 4.4.0'])
  s.add_dependency('active_scaffold_sortable', ['>= 3.2.2'])
  s.metadata['rubygems_mfa_required'] = 'true'
end
