# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Suggestions
    # This module, when injected into a controller, ensures there's an
    # suggestion available and deducts it from the context.
    module NeedsSuggestion
      extend ActiveSupport::Concern

      RegistersPermissions
        .register_permissions("#{::Decidim::Suggestions::NeedsSuggestion.name}/admin",
                              Decidim::Suggestions::Permissions,
                              Decidim::Admin::Permissions)
      RegistersPermissions
        .register_permissions("#{::Decidim::Suggestions::NeedsSuggestion.name}/public",
                              Decidim::Suggestions::Permissions,
                              Decidim::Admin::Permissions,
                              Decidim::Permissions)

      included do
        include NeedsOrganization
        include SuggestionSlug

        helper_method :current_suggestion, :current_participatory_space, :signature_has_steps?

        # Public: Finds the current Suggestion given this controller's
        # context.
        #
        # Returns the current Suggestion.
        def current_suggestion
          @current_suggestion ||= detect_suggestion
        end

        alias_method :current_participatory_space, :current_suggestion

        # Public: Wether the current suggestion belongs to an suggestion type
        # which requires one or more step before creating a signature
        #
        # Returns nil if there is no current_suggestion, true or false
        def signature_has_steps?
          return unless current_suggestion

          suggestion_type = current_suggestion.scoped_type.type
          suggestion_type.collect_user_extra_fields? || suggestion_type.validate_sms_code_on_votes?
        end

        private

        def detect_suggestion
          request.env["current_suggestion"] ||
            Suggestion.find_by(
              id: (id_from_slug(params[:slug]) || id_from_slug(params[:suggestion_slug]) || params[:suggestion_id] || params[:id]),
              organization: current_organization
            )
        end

        def permission_class_chain
          if permission_scope == :admin
            PermissionsRegistry.chain_for("#{::Decidim::Suggestions::NeedsSuggestion.name}/admin")
          else
            PermissionsRegistry.chain_for("#{::Decidim::Suggestions::NeedsSuggestion.name}/public")
          end
        end
      end
    end
  end
end
