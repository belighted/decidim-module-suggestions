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
          .deliver_later(wait: 10.seconds)
      end

      # Does nothing
      def notify_validating_suggestion
        # It has been moved into SendSuggestionToTechnicalValidation command as a standard notification
        # It would be great to move the functionality of this class, which is invoked on Suggestion#after_save,
        # to the corresponding commands to follow the architecture of Decidim.
      end

      def notify_validating_result
        notify_committee_members
        notify_author
      end

      def notify_support_result
        notify_followers
        notify_committee_members
        notify_author
      end

      def notify_committee_members
        suggestion.committee_members.approved.each do |committee_member|
          next if suggestion.author == committee_member.user

          Decidim::Suggestions::SuggestionsMailer
            .notify_state_change(suggestion, committee_member.user)
            .deliver_later(wait: 10.seconds)
        end
      end

      def notify_followers
        suggestion.followers.each do |follower|
          next if suggestion.author == follower

          Decidim::Suggestions::SuggestionsMailer
            .notify_state_change(suggestion, follower)
            .deliver_later(wait: 10.seconds)
        end
      end

      def notify_author
        Decidim::Suggestions::SuggestionsMailer
          .notify_state_change(suggestion, suggestion.author)
          .deliver_later(wait: 10.seconds)
      end
    end
  end
end
