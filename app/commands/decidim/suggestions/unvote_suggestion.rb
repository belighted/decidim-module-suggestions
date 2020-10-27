# frozen_string_literal: true

module Decidim
  module Suggestions
    # A command with all the business logic when a user or organization unvotes an suggestion.
    class UnvoteSuggestion < Rectify::Command
      # Public: Initializes the command.
      #
      # suggestion   - A Decidim::Suggestion object.
      # current_user - The current user.
      # group_id     - Decidim user group id
      def initialize(suggestion, current_user, group_id)
        @suggestion = suggestion
        @current_user = current_user
        @decidim_user_group_id = group_id
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the suggestion.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        destroy_suggestion_vote
        broadcast(:ok, @suggestion)
      end

      private

      def destroy_suggestion_vote
        @suggestion
          .votes
          .where(
            author: @current_user,
            decidim_user_group_id: @decidim_user_group_id
          )
          .destroy_all
      end
    end
  end
end
