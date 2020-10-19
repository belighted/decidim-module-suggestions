# frozen_string_literal: true

module Decidim
  module Suggestions
    # Class uses to retrieve suggestions that have been a long time in validating
    # state
    class SupportPeriodFinishedSuggestions < Rectify::Query
      # Retrieves the suggestions ready to be evaluated to decide if they've been
      # accepted or not.
      def query
        Decidim::Suggestion
          .includes(:scoped_type)
          .where(state: "published")
          .where(signature_type: "online")
          .where("signature_end_date < ?", Date.current)
      end
    end
  end
end
