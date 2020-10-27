# frozen_string_literal: true

module Decidim
  module Suggestions
    # The main admin application controller for suggestions
    class ApplicationController < Decidim::ApplicationController
      include NeedsPermission

      register_permissions(::Decidim::Suggestions::ApplicationController,
                           ::Decidim::Suggestions::Permissions,
                           ::Decidim::Admin::Permissions,
                           ::Decidim::Permissions)

      def permissions_context
        super.merge(
          current_participatory_space: try(:current_participatory_space)
        )
      end

      def permission_class_chain
        ::Decidim.permissions_registry.chain_for(::Decidim::Suggestions::ApplicationController)
      end

      def permission_scope
        :public
      end
    end
  end
end
