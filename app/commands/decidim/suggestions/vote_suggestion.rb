# frozen_string_literal: true

module Decidim
  module Suggestions
    # A command with all the business logic when a user or organization votes an suggestion.
    class VoteSuggestion < Rectify::Command
      # Public: Initializes the command.
      #
      # form - A form object with the params.
      # current_user - The current user.
      def initialize(form, current_user)
        @form = form
        @suggestion = form.suggestion
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the proposal vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        build_suggestion_vote
        set_vote_timestamp

        percentage_before = @suggestion.percentage
        vote.save!
        send_notification
        percentage_after = @suggestion.reload.percentage

        notify_percentage_change(percentage_before, percentage_after)
        notify_support_threshold_reached(percentage_after)

        broadcast(:ok, vote)
      end

      attr_reader :vote

      private

      attr_reader :form, :current_user

      def build_suggestion_vote
        @vote = @suggestion.votes.build(
          author: @current_user,
          decidim_user_group_id: form.group_id,
          encrypted_metadata: form.encrypted_metadata,
          hash_id: form.hash_id
        )
      end

      def set_vote_timestamp
        return unless timestamp_service

        @vote.assign_attributes(
          timestamp: timestamp_service.new(document: vote.encrypted_metadata).timestamp
        )
      end

      def timestamp_service
        @timestamp_service ||= Decidim.timestamp_service.to_s.safe_constantize
      end

      def send_notification
        return if vote.user_group.present?

        Decidim::EventsManager.publish(
          event: "decidim.events.suggestions.suggestion_endorsed",
          event_class: Decidim::Suggestions::EndorseSuggestionEvent,
          resource: @suggestion,
          followers: @suggestion.author.followers
        )
      end

      def notify_percentage_change(before, after)
        percentage = [25, 50, 75, 100].find do |milestone|
          before < milestone && after >= milestone
        end

        return unless percentage

        Decidim::EventsManager.publish(
          event: "decidim.events.suggestions.milestone_completed",
          event_class: Decidim::Suggestions::MilestoneCompletedEvent,
          resource: @suggestion,
          affected_users: [@suggestion.author],
          followers: @suggestion.followers - [@suggestion.author],
          extra: {
            percentage: percentage
          }
        )
      end

      def notify_support_threshold_reached(percentage)
        return unless percentage >= 100

        Decidim::EventsManager.publish(
          event: "decidim.events.suggestions.support_threshold_reached",
          event_class: Decidim::Suggestions::Admin::SupportThresholdReachedEvent,
          resource: @suggestion,
          followers: organization_admins
        )
      end

      def organization_admins
        Decidim::User.where(organization: @suggestion.organization, admin: true)
      end
    end
  end
end
