# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      module QueryProxyEagerLoading
        # Tree allowing storage of additional information about the associations
        class EnhancedTree < ::ActiveGraph::Node::Query::QueryProxyEagerLoading::AssociationTree
          attr_reader :options, :association_limit

          def initialize(model, name = nil, rel_length = nil, association_limit = nil)
            @association_limit = association_limit
            super(model, name, rel_length)
          end

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

          def add_key(key, length = nil, assoc_limit = nil)
            self[key] ||= self.class.new(model, key, length, assoc_limit)
          end

          def add_nested(key, value, length = nil, assoc_limit = nil)
            add_key(key, length, assoc_limit).add_spec(value)
          end

          def process_string(str)
            # head, rest = str.split('.', 2)
            # head, association_limit = extract_assoc_limit(head)
            # k, length = head.split('*', -2)
            # length = { max: length } if length
            #add_nested(k.to_sym, rest, length, association_limit)
            map = StringParsers::RelationParser.new.parse(str)
            add_nested(map[:rel_name].to_sym, map[:rest_str].to_s.presence, map[:length_part], map[:limit_digit])
          end

          # def extract_assoc_limit(str)
          #   transformer = StringParsers::RelationParamTransformer.new(str)
          #   [transformer.rel_name_n_length, transformer.rel_limit_number]
          # end

          def process_hash(spec)
            spec = spec.dup
            @options = spec.delete(:_options)
            super(spec)
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
