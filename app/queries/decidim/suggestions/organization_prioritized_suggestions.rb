# frozen_string_literal: true

module Decidim
  module Suggestions
    # This query retrieves the organization prioritized suggestions that will appear in the homepage
    class OrganizationPrioritizedSuggestions < Rectify::Query
      attr_reader :organization

      def initialize(organization)
        @organization = organization
      end

      def query
        Decidim::Suggestion.where(organization: organization).published.open
      end
    end
  end
end
