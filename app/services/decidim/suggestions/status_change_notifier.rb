# frozen_string_literal: true

module Decidim
  module Suggestions
    # Service that reports changes in suggestion status
    class StatusChangeNotifier
      attr_reader :suggestion

      def initialize(args = {})
        @suggestion = args.fetch(:suggestion)
      end

      # PUBLIC
      # Notifies when an suggestion has changed its status.
      #
      # * created: Notifies the author that his suggestion has been created.
      #
      # * validating: Administrators will be notified about the suggestion that
      #   requests technical validation.
      #
      # * published, discarded: Suggestion authors will be notified about the
      #   result of the technical validation process.
      #
      # * rejected, accepted: Suggestion's followers and authors will be
      #   notified about the result of the suggestion.
      def notify
        notify_suggestion_creation if suggestion.created?
        notify_validating_suggestion if suggestion.validating?
        notify_validating_result if suggestion.published? || suggestion.discarded?
        notify_support_result if suggestion.rejected? || suggestion.accepted?
      end

      private

      def notify_suggestion_creation
        Decidim::Suggestions::SuggestionsMailer
          .notify_creation(suggestion)
          .deliver_later
      end

      # Does nothing
      def notify_validating_suggestion
        # It has been moved into SendSuggestionToTechnicalValidation command as a standard notification
        # It would be great to move the functionality of this class, which is invoked on Suggestion#after_save,
        # to the corresponding commands to follow the architecture of Decidim.
      end

      def notify_validating_result
        suggestion.committee_members.approved.each do |committee_member|
          Decidim::Suggestions::SuggestionsMailer
            .notify_state_change(suggestion, committee_member.user)
            .deliver_later
        end

        Decidim::Suggestions::SuggestionsMailer
          .notify_state_change(suggestion, suggestion.author)
          .deliver_later
      end

      def notify_support_result
        suggestion.followers.each do |follower|
          Decidim::Suggestions::SuggestionsMailer
            .notify_state_change(suggestion, follower)
            .deliver_later
        end

        suggestion.committee_members.approved.each do |committee_member|
          Decidim::Suggestions::SuggestionsMailer
            .notify_state_change(suggestion, committee_member.user)
            .deliver_later
        end

        Decidim::Suggestions::SuggestionsMailer
          .notify_state_change(suggestion, suggestion.author)
          .deliver_later
      end
    end
  end
end
