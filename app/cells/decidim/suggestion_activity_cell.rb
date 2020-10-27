# frozen_string_literal: true

module Decidim
  # A cell to display when an suggestion has been published.
  class SuggestionActivityCell < ActivityCell
    def title
      I18n.t "decidim.suggestions.last_activity.new_suggestion"
    end
  end
end
