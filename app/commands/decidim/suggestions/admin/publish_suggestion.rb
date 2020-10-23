# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that publishes an
      # existing suggestion.
      class PublishSuggestion < Rectify::Command
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
          return broadcast(:invalid) if suggestion.published?

          @suggestion = Decidim.traceability.perform_action!(
            :publish,
            suggestion,
            current_user,
            visibility: "all"
          ) do
            suggestion.publish!
            increment_score
            suggestion
          end
          broadcast(:ok, suggestion)
        end

        private

        attr_reader :suggestion, :current_user

        def increment_score
          if suggestion.user_group
            Decidim::Gamification.increment_score(suggestion.user_group, :suggestions)
          else
            Decidim::Gamification.increment_score(suggestion.author, :suggestions)
          end
        end
      end
    end
  end
end
