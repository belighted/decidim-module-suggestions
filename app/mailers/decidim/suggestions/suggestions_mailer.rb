# frozen_string_literal: true

module Decidim
  module Suggestions
    # Mailer for suggestions engine.
    class SuggestionsMailer < Decidim::ApplicationMailer
      include Decidim::TranslatableAttributes
      include Decidim::SanitizeHelper

      add_template_helper Decidim::TranslatableAttributes
      add_template_helper Decidim::SanitizeHelper

      # Notifies suggestion creation
      def notify_creation(suggestion)
        return if suggestion.author.email.blank?

        @suggestion = suggestion
        @organization = suggestion.organization

        with_user(suggestion.author) do
          @subject = I18n.t(
            "decidim.suggestions.suggestions_mailer.creation_subject",
            title: translated_attribute(suggestion.title)
          )

          mail(to: "#{suggestion.author.name} <#{suggestion.author.email}>", subject: @subject)
        end
      end

      # Notify changes in state
      def notify_state_change(suggestion, user)
        return if user.email.blank?

        @organization = suggestion.organization

        with_user(user) do
          @subject = I18n.t(
            "decidim.suggestions.suggestions_mailer.status_change_for",
            title: translated_attribute(suggestion.title)
          )

          @body = I18n.t(
            "decidim.suggestions.suggestions_mailer.status_change_body_for",
            title: translated_attribute(suggestion.title),
            state: I18n.t(suggestion.state, scope: "decidim.suggestions.admin_states")
          )

          @link = suggestion_url(suggestion, host: @organization.host)

          mail(to: "#{user.name} <#{user.email}>", subject: @subject)
        end
      end

      # Notify progress to all suggestion subscribers.
      def notify_progress(suggestion, user)
        return if user.email.blank?

        @organization = suggestion.organization
        @link = suggestion_url(suggestion, host: @organization.host)

        with_user(user) do
          @body = I18n.t(
            "decidim.suggestions.suggestions_mailer.progress_report_body_for",
            title: translated_attribute(suggestion.title),
            percentage: suggestion.percentage
          )

          @subject = I18n.t(
            "decidim.suggestions.suggestions_mailer.progress_report_for",
            title: translated_attribute(suggestion.title)
          )

          mail(to: "#{user.name} <#{user.email}>", subject: @subject)
        end
      end
    end
  end
end
