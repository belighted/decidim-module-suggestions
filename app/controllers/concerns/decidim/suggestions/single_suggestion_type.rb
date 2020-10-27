# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Suggestions
    # Common methods for elements that need specific behaviour when there is only one suggestion type.
    module SingleSuggestionType
      extend ActiveSupport::Concern

      included do
        helper_method :single_suggestion_type?

        private

        def current_organization_suggestions_type
          Decidim::SuggestionsType.where(organization: current_organization)
        end

        def single_suggestion_type?
          current_organization_suggestions_type.count == 1
        end
      end
    end
  end
end
