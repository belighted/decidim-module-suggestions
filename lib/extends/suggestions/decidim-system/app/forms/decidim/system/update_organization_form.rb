# frozen_string_literal: true

require "active_support/concern"

module Suggestions
  module UpdateOrganizationFormExtend
    extend ActiveSupport::Concern

    included do

      jsonb_attribute :suggestions_settings, [
        [:sign_suggestion_minimum_age, Integer],
        [:sign_suggestion_allowed_postal_codes, String]
      ]

      def map_model(model)
        self.secondary_hosts = model.secondary_hosts.join("\n")
        self.omniauth_settings = Hash[(model.omniauth_settings || []).map do |k, v|
          [k, Decidim::OmniauthProvider.value_defined?(v) ? Decidim::AttributeEncryptor.decrypt(v) : v]
        end]
        if model.suggestions_settings.present?
          self.suggestions_settings["sign_suggestion_allowed_postal_codes"] = (model.suggestions_settings["sign_suggestion_allowed_postal_codes"] || []).join("\n")
        end
      end

      def clean_suggestions_settings
        return if suggestions_settings.blank?

        postal_codes = suggestions_settings[:sign_suggestion_allowed_postal_codes]
        if postal_codes.present?
          suggestions_settings[:sign_suggestion_allowed_postal_codes] = postal_codes.split("\n").map(&:chomp).select(&:present?)
        else
          suggestions_settings[:sign_suggestion_allowed_postal_codes] = []
        end

        suggestions_settings
      end

    end
  end

  ::Decidim::System::UpdateOrganizationForm.send(:include, UpdateOrganizationFormExtend)
end
