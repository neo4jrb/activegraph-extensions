# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        # Used to append auth scopes to query proxy eagerloading
        module EagerLoadingOrder
          def optional_order(query, path, previous_with_vars)
            node_alias = path_name(path)
            order_clause = order_clause_for_query(node_alias)
            if path.last.rel_length
              order_clause.reject! { |el| el.include?('_rel') }
              query.order("length(`#{node_alias}_path`)", *order_clause)
                   .with(*with_variables(path, node_alias, previous_with_vars))
            else
              query.order(*order_clause).with(*with_variables(path, node_alias, previous_with_vars))
            end
          end

          def order_clause_for_query(node_alias)
            (order = @order_spec&.fetch(node_alias, nil)) ? order.map(&method(:nested_order_clause).curry.call(node_alias)) : []
          end

          def nested_order_clause(node_alias, order_spec)
            [node_or_rel_alias(node_alias, order_spec), name(order_spec)].join('.')
          end

          def order_clause(key, order_spec)
            property_with_direction = name(order_spec)
            node_alias = node_aliase_for_collection(key, order_spec) || node_aliase_for_order(property_with_direction)
            [node_alias, property_with_direction].compact.join('.')
          end

          def skip_order?
            @order_spec.blank? || @order_spec.keys.all?(&:blank?)
          end
        end
      end
    end
  end
end
