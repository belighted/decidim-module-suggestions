# frozen_string_literal: true

module Decidim
  module Suggestions
    # A command with all the business logic that creates a new membership
    # request for the committee of an suggestion.
    class SpawnCommitteeRequest < Rectify::Command
      # Public: Initializes the command.
      #
      # form - Decidim::Suggestion::CommitteeMemberForm
      # current_user - Decidim::User
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        request = create_request

        if request.persisted?
          broadcast(:ok, request)
        else
          broadcast(:invalid, request)
        end
      end

      private

      attr_reader :form, :current_user

      def create_request
        request = SuggestionsCommitteeMember.new(
          decidim_suggestions_id: form.suggestion_id,
          decidim_users_id: form.user_id,
          state: form.state
        )
        return request unless request.valid?

        request.save
        request
      end
    end
  end
end
