# frozen-string_literal: true

module Decidim
  module Suggestions
    class SuggestionSentToTechnicalValidationEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent

    end
  end
end
