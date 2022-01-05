# frozen_string_literal: true

module ActiveGraphExtensions
  module Node
    module Query
      # We need earlier proxy to generate cypher in query proxy eagerloading
      module QueryProxy
        def branch(&block)
          proxy = super
          proxy.instance_variable_set(:@break_proxy, as(identity).instance_eval(&block))
          proxy
        end
      end
    end
  end
end
