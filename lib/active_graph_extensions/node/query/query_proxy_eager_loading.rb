module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        extend ActiveSupport::Concern
        include AssociationLimiting
        include ScopeEagerLoading
        include EagerLoadingOrder

        def association_tree_class
          EnhancedTree
        end

        def with_ordered_associations(spec, order, opts = {})
          @default_assoc_limit = opts[:default_assoc_limit]
          @with_vars = opts[:with_vars]
          @order_spec = order.with_indifferent_access unless spec.empty?
          @opts = opts
          with_associations(spec)
        end

        def first
          limit(1).to_a.first
        end

        class_methods do
          def rel?(order_spec)
            order_spec.is_a?(Hash) ? 0 : 1
          end
        end

        def with_associations(*spec)
          new_link.tap do |new_query_proxy|
            new_query_proxy.with_associations_tree = with_associations_tree.clone
            new_query_proxy.with_associations_tree.add_spec_and_validate(spec)
          end
        end

        private

        def query_from_association_tree
          previous_with_vars = defalut_previous_with_vars
          with_associations_tree.paths.inject(query_as(identity).with(base_query_with_vars)) do |query, path|
            with_association_query_part(query, path, previous_with_vars).tap do
              previous_with_vars << var_fix(path_name(path), :collection)
            end
          end
        end

        def defalut_previous_with_vars
          @with_vars&.dup || []
        end

        def base_query_with_vars
          [ensure_distinct(identity)] + (@with_vars || [])
        end

        def optional_match_with_where(query, path, vars)
          computed_query = super
          computed_query = limit_node_in_where_clause(computed_query, path) if multipath_with_sideload_limit?(path)
          skip_order? && !path.last.rel_length ? computed_query : optional_order(computed_query, path, vars)
        end

        def optional_match(base_query, path)
          start_path = "#{escape("#{path_name(path)}_path")}=(#{identity})"
          conf = authorized_rel(path, path_name(path[0..-1]))
          query = construct_optional_match(start_path, base_query, conf[:rels] ? path[0..-2] : path, conf[:rels])
          conf[:rels] ? apply_chain(conf[:chain], query) : query
        end

        def construct_optional_match(start_path, base_query, path, scope_rels)
          base_query.optional_match(
            "#{start_path}#{path.each_with_index.map do |element, index|
              relationship_part(element.association, path_name(path[0..index]), element.rel_length)
            end.join}#{(scope_rels || []).reverse.join}"
          )
        end

        def apply_chain(chain, query)
          chain.each do |key, links|
            query = links.inject(query) do |q, link|
              args = link.args(*key)
              args.is_a?(Array) ? q.send(link.clause, *args) : q.send(link.clause, args)
            end
          end
          query
        end

        def with_variables(path, node_alias, previous_with_vars)
          [identity, path.last.rel_length ? path_alias(node_alias) : rel_alias(node_alias), var_fix(node_alias)] +
            previous_with_vars
        end

        def before_pluck(query)
          return query if skip_order? && !include_with_path_length?
          base_query = query.order(
            (@order_spec || []).flat_map { |key, order_specs| order_specs.map(&method(:order_clause).curry.call(key)) }
          )
          query_from_chain(@postponed_chain, base_query, identity)
        end

        def node_aliase_for_collection(key, order_spec)
          "#{var(key, :collection, &:itself)}[0][#{self.class.rel?(order_spec)}]" if key.present?
        end

        def node_aliase_for_order(property_with_direction)
          identity unless @with_vars&.include?(property_with_direction.split(' ').first.to_sym)
        end

        def name(order_spec)
          Array(order_spec).flatten.last.to_s
        end

        def node_or_rel_alias(node_alias, order_spec)
          var(node_alias, order_spec.is_a?(Hash) ? :rel : nil, &:itself)
        end

        CLAUSES_TO_POSTPONE = %i[limit order skip].freeze

        def include_with_path_length?(path = @with_associations_tree)
          path.present? && (path.rel_length.present? || path.any? { |_, val| include_with_path_length?(val) })
        end

        def chain
          return super if skip_order? && !include_with_path_length?
          clauses = !skip_order? ? CLAUSES_TO_POSTPONE : %i[order]
          @postponed_chain, other_chain = super.partition { |link| clauses.include?(link.clause) }
          other_chain
        end

        def perform_query
          @_cache = ActiveGraph::Node::Query::QueryProxyEagerLoading::IdentityMap.new
          build_query
            .map do |record, eager_data|
            record = cache_and_init(record, with_associations_tree)
            eager_data.zip(with_associations_tree.paths.map(&:last)).each do |eager_records, element|
              eager_records.each do |eager_record|
                next unless eager_record.first&.type&.to_s == element.association.relationship_type.to_s
                add_to_cache(*eager_record, element)
              end
            end
            record
          end
        end
      end
    end
  end
end
