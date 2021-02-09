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
          suggestions_settings_allowed_region_allow_to?(user, action)
      end

      def suggestions_settings_minimum_age_allow_to?(user, action)
        return true if !user || user.admin?
        minimum_age = suggestions_settings_minimum_age(action)
        return true if minimum_age.blank?

        authorization = Decidim::Suggestions::UserAuthorizations.for(user).first
        return false if !authorization || authorization.metadata[:official_birth_date].blank?

        return false if (((Time.zone.now - authorization.metadata[:official_birth_date].in_time_zone) / 1.year.seconds).floor < minimum_age)

        true
      end

      def suggestions_settings_allowed_region_allow_to?(user, action)
        return true if !user || user.admin?
        allowed_region = suggestions_settings_allowed_region(action)
        return true if allowed_region.blank?
        region_codes = (Decidim::Organization::SUGGESTIONS_SETTINGS_ALLOWED_REGIONS.dig(allowed_region, :municipalities) || []).map{|m| m[:idM]}.uniq
        return true if region_codes.blank?

        authorization = Decidim::Suggestions::UserAuthorizations.for(user).first
        return false if !authorization || authorization.metadata[:postal_code].blank?

        return false unless region_codes.member?(authorization.metadata[:postal_code])

        true
      end

      def suggestions_settings_minimum_age(action)
        return if self.suggestions_settings.blank?
        self.suggestions_settings["#{action}_suggestion_minimum_age"]
      end

      def suggestions_settings_allowed_region(action)
        return if self.suggestions_settings.blank?
        self.suggestions_settings["#{action}_suggestion_allowed_region"]
      end

    end
  end

  ::Decidim::Organization.send(:include, OrganizationExtend)

end