require 'active_graph'
require 'parslet'

module ActiveGraphExtensions
  module Node
    module Query
    end
  end
  module StringParsers
  end
end

Zeitwerk::Loader.for_gem.setup

ActiveGraph::Node::Query::QueryProxy.include ActiveGraphExtensions::Node::Query::QueryProxyEagerLoading
ActiveGraph::Node::Query::QueryProxy.prepend ActiveGraphExtensions::Node::Query::QueryProxy

ActiveGraph::Node.include ActiveGraphExtensions::Node::Query::QueryProxyEagerLoading::AssociationEagerLoad
