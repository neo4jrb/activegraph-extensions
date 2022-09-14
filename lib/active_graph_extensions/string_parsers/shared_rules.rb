# frozen_string_literal: true

module ActiveGraphExtensions
  module StringParsers
    module SharedRules
      extend ActiveSupport::Concern
      VAR_CHAR = 'a-z_'
      included do
        rule(:asterisk) { str('*') }
        rule(:number) { match('[\d]').repeat(1) }
        rule(:none) { str('') }
        rule(:number?) { number | none }
        rule(:range) { str('..') }
        rule(:dot) { str('.') }
        rule(:identifier) { match("[#{VAR_CHAR}]") >> match("[#{VAR_CHAR}0-9]").repeat(0) }
        rule(:identifier?) { identifier | none }
        rule(:rel) { identifier?.as(:rel_name) }
      end
    end
  end
end
