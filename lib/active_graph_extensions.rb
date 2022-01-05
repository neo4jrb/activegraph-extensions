require 'active_graph'
require 'active_graph_extensions/version'
require 'active_graph_extensions/string_parsers/relation_parser'
require 'parslet'

module ActiveGraphExtensions
end

ActiveGraph::Node::Query::QueryProxy.include Neo4jExt::QueryProxyEagerLoading
ActiveGraph::Node::Query::QueryProxy.prepend Neo4jExt::QueryProxy

ActiveGraph::Node.include Neo4jExt::AssociationEagerLoad
