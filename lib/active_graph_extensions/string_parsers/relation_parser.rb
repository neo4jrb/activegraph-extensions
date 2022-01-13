# frozen_string_literal: true

module ActiveGraphExtensions
  module StringParsers
    # Parsing relationships with length
    class RelationParser < ::Parslet::Parser
      rule(:asterix)   { str('*') }
      rule(:digit)     { match('[\d]').repeat }
      rule(:range)     { str('..') }
      rule(:dot)       { str('.') }
      rule(:zero)      { str('0') }
      rule(:length_1)  { zero.as(:min) >> range >> digit.maybe.as(:max) }
      rule(:length_2)  { digit.maybe.as(:max) }
      rule(:length)    { asterix >> (length_1 | length_2) }
      rule(:rel)       { match('[a-z,_]').repeat.as(:rel_name) }
      rule(:limit)     { digit.as(:limit_digit) >> asterix }
      rule(:key)       { limit.maybe >> rel >> length.as(:length_part).maybe }
      rule(:anything)  { match('.').repeat }
      rule(:root)      { key >> dot.maybe >> anything.maybe.as(:rest_str) }

      rule(:rel_sequence) { infix_expression(key, [dot, 1, :left]) }
    end
  end
end
