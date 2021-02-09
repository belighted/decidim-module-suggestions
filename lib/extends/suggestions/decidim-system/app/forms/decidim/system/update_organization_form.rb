# frozen_string_literal: true

require "active_support/concern"

module Suggestions
  module UpdateOrganizationFormExtend
    extend ActiveSupport::Concern

    included do

      jsonb_attribute :suggestions_settings, [
        [:create_suggestion_minimum_age, Integer],
        [:create_suggestion_allowed_region, String],
        [:sign_suggestion_minimum_age, Integer],
        [:sign_suggestion_allowed_region, String]
      ]

    end
  end

  ::Decidim::System::UpdateOrganizationForm.send(:include, UpdateOrganizationFormExtend)
end
