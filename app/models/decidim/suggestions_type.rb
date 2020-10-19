# frozen_string_literal: true

module Decidim
  # Suggestion type.
  class SuggestionsType < ApplicationRecord
    include Decidim::HasResourcePermission

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Decidim::Organization"

    has_many :scopes,
             foreign_key: "decidim_suggestions_types_id",
             class_name: "Decidim::SuggestionsTypeScope",
             dependent: :destroy,
             inverse_of: :type

    has_many :suggestions,
             through: :scopes,
             class_name: "Decidim::Suggestion"

    enum signature_type: [:online, :offline, :any], _suffix: true

    validates :signature_type, presence: true
    validates :title, :description, presence: true

    mount_uploader :banner_image, Decidim::BannerImageUploader

    def allowed_signature_types_for_suggestions
      return %w(online offline any) if any_signature_type?

      Array(signature_type.to_s)
    end

    def allow_resource_permissions?
      true
    end

    def mounted_admin_engine
      "decidim_admin_suggestions"
    end

    def mounted_params
      { host: organization.host }
    end
  end
end
