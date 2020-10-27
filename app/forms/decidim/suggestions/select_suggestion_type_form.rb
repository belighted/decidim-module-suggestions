# frozen_string_literal: true

module Decidim
  module Suggestions
    # A form object used to collect the suggestion type for an suggestion.
    class SelectSuggestionTypeForm < Form
      mimic :suggestion

      attribute :type_id, Integer

      validates :type_id, presence: true
    end
  end
end
