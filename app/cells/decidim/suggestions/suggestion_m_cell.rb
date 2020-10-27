# frozen_string_literal: true

module Decidim
  module Suggestions
    # This cell renders the Medium (:m) suggestion card
    # for an given instance of an Suggestion
    class SuggestionMCell < Decidim::CardMCell
      include Decidim::Suggestions::Engine.routes.url_helpers

      property :state

      private

      def title
        decidim_html_escape(translated_attribute(model.title))
      end

      def hashtag
        decidim_html_escape(model.hashtag)
      end

      def has_state?
        true
      end

      # Explicitely commenting the used I18n keys so their are not flagged as unused
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.accepted')
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.created')
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.discarded')
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.published')
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.rejected')
      # i18n-tasks-use t('decidim.suggestions.show.badge_name.validating')
      def badge_name
        I18n.t(model.state, scope: "decidim.suggestions.show.badge_name")
      end

      def state_classes
        case state
        when "accepted", "published"
          ["success"]
        when "rejected", "discarded"
          ["alert"]
        when "validating"
          ["warning"]
        else
          ["muted"]
        end
      end

      def resource_path
        suggestion_path(model)
      end

      def resource_icon
        icon "suggestions", class: "icon--big"
      end

      def authors
        [present(model).author] +
          model.committee_members.approved.non_deleted.excluding_author.map { |member| present(member.user) }
      end
    end
  end
end
