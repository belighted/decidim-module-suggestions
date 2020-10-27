# frozen-string_literal: true

module Decidim
  module Suggestions
    class EndorseSuggestionEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent

      def i18n_scope
        "decidim.suggestions.events.endorse_suggestion_event"
      end
    end
  end
end
