# frozen_string_literal: true

module Decidim
  module Suggestions
    # A presenter to render statistics in the homepage.
    class SuggestionStatsPresenter < Rectify::Presenter
      attribute :suggestion, Decidim::Suggestion

      def supports_count
        suggestion.suggestion_supports_count
      end

      def comments_count
        Rails.cache.fetch(
          "suggestion/#{suggestion.id}/comments_count",
          expires_in: Decidim::Suggestions.stats_cache_expiration_time
        ) do
          Decidim::Comments::Comment.where(root_commentable: suggestion).count
        end
      end

      def meetings_count
        Rails.cache.fetch(
          "suggestion/#{suggestion.id}/meetings_count",
          expires_in: Decidim::Suggestions.stats_cache_expiration_time
        ) do
          Decidim::Meetings::Meeting.where(component: meetings_component).count
        end
      end

      def assistants_count
        Rails.cache.fetch(
          "suggestion/#{suggestion.id}/assistants_count",
          expires_in: Decidim::Suggestions.stats_cache_expiration_time
        ) do
          result = 0
          Decidim::Meetings::Meeting.where(component: meetings_component).each do |meeting|
            result += meeting.attendees_count || 0
          end

          result
        end
      end

      private

      def meetings_component
        @meetings_component ||= Decidim::Component.find_by(participatory_space: suggestion, manifest_name: "meetings")
      end
    end
  end
end
