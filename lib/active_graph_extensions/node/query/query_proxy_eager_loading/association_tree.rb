module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        module AssociationTree
          def add_spec_and_validate(spec)
            add_spec(spec)
            validate_for_zero_length_paths
          end

          def validate_for_zero_length_paths
            fail 'Can not eager load more than one zero length path.' if values.count(&:zero_length_path?) > 1
          end

          def zero_length_path?
            rel_length&.fetch(:min, nil)&.to_s == '0' || values.any?(&:zero_length_path?)
          end

          def process_string(str)
            map = StringParsers::RelationParser.new.parse(str)
            add_nested(map[:rel_name].to_sym, map[:rest_str].to_s.presence, map[:length_part])
          end

          def target_class(model, key)
            association = model.associations[key.to_sym]
            fail "Invalid association: #{[*path, key].join('.')}" unless association
            model.associations[key].target_class
          end
        end
      end
    end
  end
end
