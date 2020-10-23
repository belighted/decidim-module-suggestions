# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that unpublishes an
      # existing suggestion.
      class UnpublishSuggestion < Rectify::Command
        # Public: Initializes the command.
        #
        # suggestion - Decidim::Suggestion
        # current_user - the user performing the action
        def initialize(suggestion, current_user)
          @suggestion = suggestion
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless suggestion.published?

          @suggestion = Decidim.traceability.perform_action!(
            :unpublish,
            suggestion,
            current_user
          ) do
            suggestion.unpublish!
            suggestion
          end
          broadcast(:ok, suggestion)
        end

        private

        attr_reader :suggestion, :current_user
      end
    end
  end
end
