# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # The main admin application controller for suggestions
      class ApplicationController < Decidim::Admin::ApplicationController
        layout "decidim/admin/suggestions"

        register_permissions(::Decidim::Suggestions::Admin::ApplicationController,
                             ::Decidim::Suggestions::Permissions,
                             ::Decidim::Admin::Permissions)

        def permissions_context
          super.merge(
            current_participatory_space: try(:current_participatory_space)
          )
        end

        def permission_class_chain
          ::Decidim.permissions_registry.chain_for(::Decidim::Suggestions::Admin::ApplicationController)
        end
      end
    end
  end
end
