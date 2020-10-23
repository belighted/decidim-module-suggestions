# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A form object used to collect the all the scopes related to an
      # suggestion type
      class SuggestionTypeScopeForm < Form
        mimic :suggestions_type_scope

        attribute :supports_required, Integer
        attribute :decidim_scopes_id, Integer

        validates :supports_required,
                  presence: true,
                  numericality: {
                    only_integer: true,
                    greater_than: 0
                  }
      end
    end
  end
end
