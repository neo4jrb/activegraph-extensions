# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        module AssociationLimiting
          def self.included(base)
            base.attr_reader(:default_assoc_limit)
          end

          private

          def rel_collection_str(path)
            limit = association_limit(path)
            collection_name = "[#{relationship_name(path)}, #{escape(path_name(path))}] "
            collection = limit.present? ? "apoc.agg.slice(#{collection_name}, 0, #{limit})" : "collect(#{collection_name})"
            "#{collection} AS #{escape("#{path_name(path)}_collection")}"
          end

          def relationship_name(path)
          if path.last.rel_length
            "last(relationships(#{escape("#{path_name(path)}_path")}))"
          else
            escape("#{path_name(path)}_rel")
          end

          end

          def convert_to_list(collection_name, limit)
            limit.present? ? "apoc.agg.slice(#{collection_name}, 0, #{limit})" : "collect(#{collection_name})"
          end

          def association_limit(path)
            return if multipath?(path)

            limit = path.last&.association_limit
            limit.blank? || limit.to_i > default_assoc_limit ? default_assoc_limit : limit
          end

          def with_association_query_part(base_query, path, previous_with_vars)
            with_args = [identity, rel_collection_str(path), *previous_with_vars]

            optional_match_with_where(base_query, path, previous_with_vars).with(with_args)
          end

          def limit_node_in_where_clause(query, path)
            (path.length - 1).times.inject(query) do |query_with_where, index|
              query_with_where.where("`#{path_name(path[0..index])}` in [i IN #{node_from_collection(path[0..index])} | i[1]]")
            end
          end

          def node_from_collection(path_step)
            "`#{path_name(path_step)}_collection`"
          end

          def path_alias(node_alias)
            var_fix(node_alias, :path)
          end

          def rel_alias(node_alias)
            var_fix(node_alias, :rel)
          end

          def multipath?(path)
            path.size > 1
          end

          def association_limit_present?(path)
            association_limit(path).present?
          end

          def multipath_with_sideload_limit?(path)
            multipath?(path) && association_limit_present?(path[0..0])
          end
        end
      end
    end
  end
end
