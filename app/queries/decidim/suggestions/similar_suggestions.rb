# frozen_string_literal: true

module Decidim
  module Suggestions
    # Class uses to retrieve similar suggestions types.
    class SimilarSuggestions < Rectify::Query
      include Decidim::TranslationsHelper
      include CurrentLocale

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # organization - Decidim::Organization
      # form - Decidim::Suggestions::PreviousForm
      def self.for(organization, form)
        new(organization, form).query
      end

      # Initializes the class.
      #
      # organization - Decidim::Organization
      # form - Decidim::Suggestions::PreviousForm
      def initialize(organization, form)
        @organization = organization
        @form = form
      end

      # Retrieves similar suggestions
      def query
        Suggestion
          .published
          .where(organization: @organization)
          .where(
            "GREATEST(#{title_similarity}, #{description_similarity}) >= ?",
            form.title,
            form.description,
            Decidim::Suggestions.similarity_threshold
          )
          .limit(Decidim::Suggestions.similarity_limit)
      end

      private

      attr_reader :form

      def title_similarity
        "similarity(title->>'#{current_locale}', ?)"
      end

      def description_similarity
        "similarity(description->>'#{current_locale}', ?)"
      end
    end
  end
end
