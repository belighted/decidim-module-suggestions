# frozen_string_literal: true

module Decidim
  module Suggestions
    # Helper method related to suggestion object and its internal state.
    module SuggestionHelper
      include Decidim::SanitizeHelper
      include Decidim::ResourceVersionsHelper

      # Public: The css class applied based on the suggestion state to
      #         the suggestion badge.
      #
      # suggestion - Decidim::Suggestion
      #
      # Returns a String.
      def state_badge_css_class(suggestion)
        return "success" if suggestion.accepted? || suggestion.debatted? || suggestion.published?
        return "alert" if suggestion.classified?

        "warning"
      end

      # Public: The state of an suggestion in a way a human can understand.
      #
      # suggestion - Decidim::Suggestion.
      #
      # Returns a String.
      def humanize_state(suggestion)
        # I18n.t(suggestion.accepted? ? "accepted" : "expired",
        #        scope: "decidim.suggestions.states",
        #        default: :expired)
        return I18n.t("expired", scope: "decidim.suggestions.states") if suggestion.rejected?

        I18n.t(suggestion.state, scope: "decidim.suggestions.states")
      end

      # Public: The state of an suggestion from an administration perspective in
      # a way that a human can understand.
      #
      # state - String
      #
      # Returns a String
      def humanize_admin_state(state)
        I18n.t(state, scope: "decidim.suggestions.admin_states", default: :created)
      end

      def popularity_tag(suggestion)
        content_tag(:div, class: "extra__popularity popularity #{popularity_class(suggestion)}".strip) do
          5.times do
            concat(content_tag(:span, class: "popularity__item") {})
          end

          concat(content_tag(:span, class: "popularity__desc") do
            I18n.t("decidim.suggestions.suggestions.vote_cabin.supports_required",
                   total_supports: suggestion.scoped_type.supports_required)
          end)
        end
      end

      def popularity_class(suggestion)
        return "popularity--level1" if popularity_level1?(suggestion)
        return "popularity--level2" if popularity_level2?(suggestion)
        return "popularity--level3" if popularity_level3?(suggestion)
        return "popularity--level4" if popularity_level4?(suggestion)
        return "popularity--level5" if popularity_level5?(suggestion)

        ""
      end

      def popularity_level1?(suggestion)
        suggestion.percentage.positive? && suggestion.percentage < 40
      end

      def popularity_level2?(suggestion)
        suggestion.percentage >= 40 && suggestion.percentage < 60
      end

      def popularity_level3?(suggestion)
        suggestion.percentage >= 60 && suggestion.percentage < 80
      end

      def popularity_level4?(suggestion)
        suggestion.percentage >= 80 && suggestion.percentage < 100
      end

      def popularity_level5?(suggestion)
        suggestion.percentage >= 100
      end

      def authorized_vote_modal_button(suggestion, html_options, &block)
        return if current_user && action_authorized_to("vote", resource: suggestion, permissions_holder: suggestion.type).ok?

        tag = "button"
        html_options ||= {}

        if !current_user
          html_options["data-open"] = "loginModal"
        else
          html_options["data-open"] = "authorizationModal"
          html_options["data-open-url"] = authorization_sign_modal_suggestion_path(suggestion)
        end

        html_options["onclick"] = "event.preventDefault();"

        send("#{tag}_to", "", html_options, &block)
      end

      def can_edit_custom_signature_end_date?(suggestion)
        return false unless suggestion.custom_signature_end_date_enabled?

        suggestion.created? || suggestion.validating?
      end

      def can_edit_area?(suggestion)
        return false unless suggestion.area_enabled?

        suggestion.created? || suggestion.validating?
      end

      def organization_suggestions_settings_validation_message(suggestion, action)
        org = suggestion&.organization || current_organization
        minimum_age_allow = org.suggestions_settings_minimum_age_allow_to?(current_user, action)
        allowed_region_allow = org.suggestions_settings_allowed_region_allow_to?(current_user, action)
        message = ''
        t_scope = "decidim.suggestions.suggestions.organization_suggestions_settings.#{action}"
        unless minimum_age_allow
          message = t("minimum_age_not_valid", scope: t_scope, minimum_age: org.suggestions_settings_minimum_age(action))
        end
        unless allowed_region_allow
          region_name = t(org.suggestions_settings_allowed_region(action), scope: "decidim.suggestions.organization_suggestions_settings.allowed_regions")
          message = t("allowed_region_not_valid", scope: t_scope, region_name: region_name)
        end
        if !minimum_age_allow && !allowed_region_allow
          region_name = t(org.suggestions_settings_allowed_region(action), scope: "decidim.suggestions.organization_suggestions_settings.allowed_regions")
          message = t("minimum_age_and_allowed_region_not_valid", scope: t_scope,
                      minimum_age: org.suggestions_settings_minimum_age(action),
                      region_name: region_name)
        end
        message
      end

    end
  end
end
