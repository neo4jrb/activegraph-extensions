# frozen_string_literal: true

module ActiveGraphExtensions
  module StringParsers
    # Parsing relationships with length
    class RelationParser < ::Parslet::Parser
      include SharedRules

      # TODO: It is very bad to build a grammar with none terminals. Please note that none here are necessary to
      # mimic the previous behavior of `repeat` which is `repeat(0)` which effectively allows empty strings as
      # identifiers
      rule(:zero) { str('0') }
      rule(:length_1) { zero.as(:min) >> range >> number?.maybe.as(:max) }
      rule(:length_2) { number?.maybe.as(:max) }
      rule(:length) { asterisk >> (length_1 | length_2) }
      rule(:limit) { number?.as(:limit_digit) >> asterisk }
      rule(:key) { limit.maybe >> rel >> length.as(:length_part).maybe }
      rule(:anything) { match('.').repeat }
      rule(:root) { key >> dot.maybe >> anything.maybe.as(:rest_str) }
      rule(:rel_sequence) { infix_expression(key, [dot, 1, :left]) }
    end
  end
end
