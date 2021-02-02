# frozen_string_literal: true

module Decidim
  module Suggestions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        if read_admin_dashboard_action?
          user_can_read_admin_dashboard?
          return permission_action
        end

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Suggestions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        # Non-logged users permissions
        public_report_content_action?
        list_public_suggestions?
        read_public_suggestion?
        search_suggestion_types_and_scopes?
        request_membership?

        return permission_action unless user

        create_suggestion?

        vote_suggestion?
        sign_suggestion?
        unvote_suggestion?

        suggestion_attachment?

        permission_action
      end

      private

      def suggestion
        @suggestion ||= context.fetch(:suggestion, nil) || context.fetch(:current_participatory_space, nil)
      end

      def suggestion_type
        @suggestion_type ||= context[:suggestion_type]
      end

      def list_public_suggestions?
        allow! if permission_action.subject == :suggestion &&
                  permission_action.action == :list
      end

      def read_public_suggestion?
        return unless [:suggestion, :participatory_space].include?(permission_action.subject) &&
                      permission_action.action == :read

        return allow! if suggestion.published? || suggestion.rejected? || suggestion.accepted?
        return allow! if user && (suggestion.has_authorship?(user) || user.admin?)

        # Unregistered users should see unpublished suggestion in order to support/vote them via shared link
        return allow! if suggestion.created? || suggestion.validating?

        disallow!
      end

      def search_suggestion_types_and_scopes?
        return unless permission_action.action == :search
        return unless [:suggestion_type, :suggestion_type_scope, :suggestion_type_signature_types].include?(permission_action.subject)

        allow!
      end

      def create_suggestion?
        return unless permission_action.subject == :suggestion &&
                      permission_action.action == :create

        toggle_allow(creation_enabled?)
      end

      def creation_enabled?
        Decidim::Suggestions.creation_enabled &&
          organization_suggestions_settings_allow_to_create? &&
          (Decidim::Suggestions.do_not_require_authorization ||
            UserAuthorizations.for(user).any? ||
            Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?)
      end

      def request_membership?
        return unless permission_action.subject == :suggestion &&
                      permission_action.action == :request_membership

        toggle_allow(can_request_membership?)
      end

      def can_request_membership?
        return access_request_without_user? if user.blank?

        access_request_membership?
      end

      def access_request_without_user?
        !suggestion.published? && suggestion.promoting_committee_enabled? || Decidim::Suggestions.do_not_require_authorization
      end

      def access_request_membership?
        !suggestion.published? &&
          suggestion.promoting_committee_enabled? &&
          !suggestion.has_authorship?(user) &&
          (
            Decidim::Suggestions.do_not_require_authorization ||
            UserAuthorizations.for(user).any? ||
            Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
          )
      end

      def has_suggestions?
        (SuggestionsCreated.by(user) | SuggestionsPromoted.by(user)).any?
      end

      def read_admin_dashboard_action?
        permission_action.action == :read &&
          permission_action.subject == :admin_dashboard
      end

      def user_can_read_admin_dashboard?
        return unless user

        allow! if has_suggestions?
      end

      def vote_suggestion?
        return unless permission_action.action == :vote &&
                      permission_action.subject == :suggestion

        toggle_allow(can_vote?)
      end

      def authorized?(permission_action, resource: nil, permissions_holder: nil)
        return unless resource || permissions_holder

        ActionAuthorizer.new(user, permission_action, permissions_holder, resource).authorize.ok?
      end

      def unvote_suggestion?
        return unless permission_action.action == :unvote &&
          permission_action.subject == :suggestion

        can_unvote = (suggestion.accepts_online_unvotes? || suggestion.unvotes_enabled_for_user?(user)) &&
          suggestion.organization&.id == user.organization&.id &&
          organization_suggestions_settings_allow_to_vote? &&
          suggestion.votes.where(decidim_author_id: user.id, decidim_user_group_id: decidim_user_group_id).any? &&
          (can_user_support?(suggestion) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?) &&
          authorized?(:vote, resource: suggestion, permissions_holder: suggestion.type)

        toggle_allow(can_unvote)
      end

      def suggestion_attachment?
        return unless permission_action.action == :add_attachment &&
                      permission_action.subject == :suggestion

        toggle_allow(suggestion_type.attachments_enabled?)
      end

      def public_report_content_action?
        return unless permission_action.action == :create &&
                      permission_action.subject == :moderation

        allow!
      end

      def sign_suggestion?
        return unless permission_action.action == :sign_suggestion &&
                      permission_action.subject == :suggestion

        can_sign = can_vote? &&
                   context.fetch(:signature_has_steps, false)

        toggle_allow(can_sign)
      end

      def decidim_user_group_id
        context.fetch(:group_id, nil)
      end

      def can_vote?
        (suggestion.votes_enabled? || suggestion.votes_enabled_for_user?(user)) &&
          suggestion.organization&.id == user.organization&.id &&
          organization_suggestions_settings_allow_to_vote? &&
          suggestion.votes.where(decidim_author_id: user.id, decidim_user_group_id: decidim_user_group_id).empty? &&
          (can_user_support?(suggestion) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?) &&
          authorized?(:vote, resource: suggestion, permissions_holder: suggestion.type)
      end

      def can_user_support?(suggestion)
        !suggestion.offline_signature_type? && (
          Decidim::Suggestions.do_not_require_authorization ||
          UserAuthorizations.for(user).any?
        )
      end

      def organization_suggestions_settings_allow_to_create?
        organization_suggestions_settings_allow_to?('create')
      end

      def organization_suggestions_settings_allow_to_vote?
        organization_suggestions_settings_allow_to?('sign')
      end

      def organization_suggestions_settings_allow_to?(action)
        return true if user.admin?

        organization = suggestion&.organization || user&.organization
        settings = organization&.suggestions_settings
        return true if settings.blank?

        authorization = UserAuthorizations.for(user).first #{|auth| auth.metadata[:official_birth_date].present?}
        return true unless authorization

        minimum_age = settings["#{action}_suggestion_minimum_age"]
        return false if minimum_age.present? && authorization.metadata[:official_birth_date].present? &&
          (((Time.zone.now - authorization.metadata[:official_birth_date].in_time_zone) / 1.year.seconds).floor < minimum_age)

        # authorization = UserAuthorizations.for(user).first {|auth| auth.metadata[:postal_code].present?}
        allowed_postal_codes = settings["#{action}_suggestion_allowed_postal_codes"]
        return false if allowed_postal_codes.present? && authorization.metadata[:postal_code].present? &&
          !allowed_postal_codes.member?(authorization.metadata[:postal_code])

        true
      end

    end
  end
end
