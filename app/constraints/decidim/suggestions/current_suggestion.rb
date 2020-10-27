# frozen_string_literal: true

module Decidim
  module Suggestions
    # This class infers the current suggestion we're scoped to by
    # looking at the request parameters and the organization in the request
    # environment, and injects it into the environment.
    class CurrentSuggestion
      include SuggestionSlug

      # Public: Matches the request against an initative and injects it
      #         into the environment.
      #
      # request - The request that holds the suggestion relevant
      #           information.
      #
      # Returns a true if the request matched, false otherwise
      def matches?(request)
        env = request.env

        @organization = env["decidim.current_organization"]
        return false unless @organization

        current_suggestion(env, request.params) ? true : false
      end

      private

      def current_suggestion(env, params)
        env["decidim.current_participatory_space"] ||= Suggestion.find_by(id: id_from_slug(params[:suggestion_slug]))
      end
    end
  end
end
