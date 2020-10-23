# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller that allows managing suggestions types
      # permissions in the admin panel.
      class SuggestionsTypesPermissionsController < Decidim::Admin::ResourcePermissionsController
        layout "decidim/admin/suggestions"

        register_permissions(::Decidim::Suggestions::Admin::SuggestionsTypesPermissionsController,
                             ::Decidim::Suggestions::Permissions,
                             ::Decidim::Admin::Permissions)

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::Suggestions::Admin::SuggestionsTypesPermissionsController)
        end
      end
    end
  end
end
