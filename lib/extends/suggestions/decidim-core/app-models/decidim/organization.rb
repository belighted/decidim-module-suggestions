# frozen_string_literal: true

require "active_support/concern"

module Suggestions
  module OrganizationExtend
    extend ActiveSupport::Concern

    included do

      #
      # `action` is one of:
      # - create
      # - sign
      #
      def suggestions_settings_allow_to?(user, action)
        suggestions_settings_minimum_age_allow_to?(user, action) &&
          suggestions_settings_allowed_postal_codes_allow_to?(user, action)
      end

      def suggestions_settings_minimum_age_allow_to?(user, action)
        return true if !user || user.admin?
        return true if self.suggestions_settings.blank?
        minimum_age = self.suggestions_settings["#{action}_suggestion_minimum_age"]
        return true if minimum_age.blank?

        authorization = Decidim::Suggestions::UserAuthorizations.for(user).first
        return false if !authorization || authorization.metadata[:official_birth_date].blank?

        return false if (((Time.zone.now - authorization.metadata[:official_birth_date].in_time_zone) / 1.year.seconds).floor < minimum_age)

        true
      end

      def suggestions_settings_allowed_postal_codes_allow_to?(user, action)
        return true if !user || user.admin?
        return true if self.suggestions_settings.blank?
        allowed_postal_codes = self.suggestions_settings["#{action}_suggestion_allowed_postal_codes"]
        return true if allowed_postal_codes.blank?

        authorization = Decidim::Suggestions::UserAuthorizations.for(user).first
        return false if !authorization || authorization.metadata[:postal_code].blank?

        return false unless allowed_postal_codes.member?(authorization.metadata[:postal_code])

        true
      end

      def suggestions_settings_minimum_age(action)
        return if self.suggestions_settings.blank?
        self.suggestions_settings["#{action}_suggestion_minimum_age"]
      end

    end
  end

  ::Decidim::Organization.send(:include, OrganizationExtend)

end