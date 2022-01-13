require 'active_graph'
require 'parslet'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect 'version' => 'VERSION'
loader.ignore(File.expand_path('activegraph-extensions.rb', __dir__))
loader.setup

module ActiveGraphExtensions
end

ActiveGraph::Node::Query::QueryProxy.include ActiveGraphExtensions::Node::Query::QueryProxyEagerLoading
ActiveGraph::Node::Query::QueryProxy.prepend ActiveGraphExtensions::Node::Query::QueryProxy

ActiveGraph::Node.include ActiveGraphExtensions::Node::Query::QueryProxyEagerLoading::AssociationEagerLoad
