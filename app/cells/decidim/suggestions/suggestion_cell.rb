# frozen_string_literal: true

module Decidim
  module Suggestions
    # This cell renders the process card for an instance of an Suggestion
    # the default size is the Medium Card (:m)
    class SuggestionCell < Decidim::ViewModel
      def show
        cell card_size, model, options
      end

      private

      def card_size
        "decidim/suggestions/suggestion_m"
      end
    end
  end
end
