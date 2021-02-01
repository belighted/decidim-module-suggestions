# frozen_string_literal: true

require "active_support/concern"

module Suggestions
  module UpdateOrganizationFormExtend
    extend ActiveSupport::Concern

    included do

      jsonb_attribute :suggestions_settings, [
        [:create_suggestion_minimum_age, Integer],
        [:create_suggestion_allowed_postal_codes, String],
        [:sign_suggestion_minimum_age, Integer],
        [:sign_suggestion_allowed_postal_codes, String]
      ]

      def map_model(model)
        self.secondary_hosts = model.secondary_hosts.join("\n")
        self.omniauth_settings = Hash[(model.omniauth_settings || []).map do |k, v|
          [k, Decidim::OmniauthProvider.value_defined?(v) ? Decidim::AttributeEncryptor.decrypt(v) : v]
        end]
        if model.suggestions_settings.present?
          self.suggestions_settings["create_suggestion_allowed_postal_codes"] = (model.suggestions_settings["create_suggestion_allowed_postal_codes"] || []).join("\n")
          self.suggestions_settings["sign_suggestion_allowed_postal_codes"] = (model.suggestions_settings["sign_suggestion_allowed_postal_codes"] || []).join("\n")
        end
      end

      def clean_suggestions_settings
        return if suggestions_settings.blank?

        suggestions_settings[:create_suggestion_allowed_postal_codes] = clean_suggestion_allowed_postal_codes(:create)
        suggestions_settings[:sign_suggestion_allowed_postal_codes] = clean_suggestion_allowed_postal_codes(:sign)

        suggestions_settings
      end

      private

      def clean_suggestion_allowed_postal_codes(action)
        postal_codes = suggestions_settings.dig("#{action}_suggestion_allowed_postal_codes".to_sym)
        return [] if postal_codes.blank?
        postal_codes.split("\n").map(&:chomp).select(&:present?)
      end

    end
  end

  ::Decidim::System::UpdateOrganizationForm.send(:include, UpdateOrganizationFormExtend)
end
