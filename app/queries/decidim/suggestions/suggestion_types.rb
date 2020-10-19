# frozen_string_literal: true

module Decidim
  module Suggestions
    # Class uses to retrieve the available suggestion types.
    class SuggestionTypes < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # organization - Decidim::Organization
      def self.for(organization)
        new(organization).query
      end

      # Initializes the class.
      #
      # organization - Decidim::Organization
      def initialize(organization)
        @organization = organization
      end

      # Retrieves the available suggestion types for the given organization.
      def query
        SuggestionsType.where(organization: @organization)
      end
    end
  end
end
