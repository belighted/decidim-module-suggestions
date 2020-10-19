# frozen_string_literal: true

module Decidim
  module Suggestions
    # Service that notifies progress for an suggestion
    class ProgressNotifier
      attr_reader :suggestion

      def initialize(args = {})
        @suggestion = args.fetch(:suggestion)
      end

      # PUBLIC: Notifies the support progress of the suggestion.
      #
      # Notifies to Suggestion's authors and followers about the
      # number of supports received by the suggestion.
      def notify
        suggestion.followers.each do |follower|
          Decidim::Suggestions::SuggestionsMailer
            .notify_progress(suggestion, follower)
            .deliver_later
        end

        suggestion.committee_members.approved.each do |committee_member|
          Decidim::Suggestions::SuggestionsMailer
            .notify_progress(suggestion, committee_member.user)
            .deliver_later
        end

        Decidim::Suggestions::SuggestionsMailer
          .notify_progress(suggestion, suggestion.author)
          .deliver_later
      end
    end
  end
end
