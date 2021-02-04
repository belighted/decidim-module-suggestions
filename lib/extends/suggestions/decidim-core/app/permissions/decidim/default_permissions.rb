# frozen_string_literal: true

require "active_support/concern"

module Suggestions
  module DefaultPermissionsExtend
    extend ActiveSupport::Concern

    included do
      def available_verification_workflows
        Decidim::Verifications::Adapter.from_collection(
          user.organization.available_authorizations & Decidim.authorization_workflows.map(&:name)
        )
      end
    end
  end

  ::Decidim::DefaultPermissions.send(:include, DefaultPermissionsExtend)
end
