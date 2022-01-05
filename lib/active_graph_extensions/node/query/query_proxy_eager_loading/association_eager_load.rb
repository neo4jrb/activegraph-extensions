# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        # Used for eager loading associations with scope
        module AssociationEagerLoad
          extend ActiveSupport::Concern

          class_methods do
            def associations_to_eagerload
              @associations_to_eagerload
            end

            def association_nodes(key, ids, filter)
              send(@associations_to_eagerload[key], ids, filter)
            end

            def eagerload_associations(config)
              @associations_to_eagerload = config
            end

            def eagerload_association?(key)
              @associations_to_eagerload.keys.include?(key)
            end
          end
        end
      end
    end
  end
end
