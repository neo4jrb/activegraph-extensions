lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'active_graph_extensions/version'

Gem::Specification.new do |s|
  s.name     = 'activegraph-extensions'
  s.version  = ActiveGraphExtensions::VERSION

  s.required_ruby_version = '>= 2.5'

  s.authors  = 'Amit Suryavanshi'
  s.email    = 'amitbsuryavabshi@mail.com'
  s.homepage = 'https://github.com/neo4jrb/activegraph-extensions/'
  s.summary = 'Additional features to activegraph'
  s.license = 'MIT'
  s.description = <<-DESCRIPTION
  Additional features to activegraph, like sideload limiting, authorizing sideloads etc.
DESCRIPTION

  s.require_path = 'lib'
  s.files = Dir.glob('{bin,lib,config}/**/*') + %w(README.md CHANGELOG.md CONTRIBUTORS Gemfile activegraph-extensions.gemspec)
  s.executables = []
  s.extra_rdoc_files = %w( README.md )
  s.rdoc_options = ['--quiet', '--title', 'Neo4j.rb', '--line-numbers', '--main', 'README.rdoc', '--inline-source']

  s.platform = 'java'

  s.add_dependency('parslet')
  s.add_dependency('activegraph')
  
  s.add_development_dependency('neo4j-rake_tasks', '>= 0.3.0')
  s.add_development_dependency('pry')
  s.add_development_dependency('railties', '>= 4.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('rubocop', '>= 0.56.0')
  s.add_development_dependency('dryspec')
  s.add_development_dependency('rspec', '< 3.10') # Cannot proxy frozen objects
end
