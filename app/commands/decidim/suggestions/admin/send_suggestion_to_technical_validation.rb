# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that sends an
      # existing suggestion to technical validation.
      class SendSuggestionToTechnicalValidation < Rectify::Command
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
          @suggestion = Decidim.traceability.perform_action!(
            :send_to_technical_validation,
            suggestion,
            current_user
          ) do
            suggestion.validating!
            suggestion
          end

          notify_admins

          broadcast(:ok, suggestion)
        end

        private

        attr_reader :suggestion, :current_user

        def notify_admins
          affected_users = Decidim::User.org_admins_except_me(current_user).all

          data = {
            event: "decidim.events.suggestions.admin.suggestion_sent_to_technical_validation",
            event_class: Decidim::Suggestions::Admin::SuggestionSentToTechnicalValidationEvent,
            resource: suggestion,
            affected_users: affected_users,
            force_send: true
          }

          Decidim::EventsManager.publish(data)
        end
      end
    end
  end
end
