# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin
          return permission_action unless user

          user_can_enter_space_area?

          return permission_action if suggestion && !suggestion.is_a?(Decidim::Suggestion)

          user_can_read_participatory_space?

          if !user.admin? && suggestion&.has_authorship?(user)
            suggestion_committee_action?
            suggestion_user_action?
            attachment_action?

            return permission_action
          end

          if !user.admin? && has_suggestions?
            read_suggestion_list_action?

            return permission_action
          end

          return permission_action unless user.admin?

          suggestion_type_action?
          suggestion_type_scope_action?
          suggestion_committee_action?
          suggestion_admin_user_action?
          suggestion_export_action?
          moderator_action?
          allow! if permission_action.subject == :attachment

          permission_action
        end

        private

        def suggestion
          @suggestion ||= context.fetch(:suggestion, nil) || context.fetch(:current_participatory_space, nil)
        end

        def user_can_read_participatory_space?
          return unless permission_action.action == :read &&
                        permission_action.subject == :participatory_space

          toggle_allow(user.admin? || suggestion.has_authorship?(user))
        end

        def user_can_enter_space_area?
          return unless permission_action.action == :enter &&
                        permission_action.subject == :space_area &&
                        context.fetch(:space_name, nil) == :suggestions

          toggle_allow(user.admin? || has_suggestions?)
        end

        def has_suggestions?
          (SuggestionsCreated.by(user) | SuggestionsPromoted.by(user)).any?
        end

        def attachment_action?
          return unless permission_action.subject == :attachment

          disallow! && return unless suggestion.attachments_enabled?

          attachment = context.fetch(:attachment, nil)
          attached = attachment&.attached_to

          case permission_action.action
          when :update, :destroy
            toggle_allow(attached && attached.is_a?(Decidim::Suggestion))
          when :read, :create
            allow!
          else
            disallow!
          end
        end

        def suggestion_type_action?
          return unless [:suggestion_type, :suggestions_type].include? permission_action.subject

          suggestion_type = context.fetch(:suggestion_type, nil)

          case permission_action.action
          when :destroy
            scopes_are_empty = suggestion_type && suggestion_type.scopes.all? { |scope| scope.suggestions.empty? }
            toggle_allow(scopes_are_empty)
          else
            allow!
          end
        end

        def suggestion_type_scope_action?
          return unless permission_action.subject == :suggestion_type_scope

          suggestion_type_scope = context.fetch(:suggestion_type_scope, nil)

          case permission_action.action
          when :destroy
            scopes_is_empty = suggestion_type_scope && suggestion_type_scope.suggestions.empty?
            toggle_allow(scopes_is_empty)
          else
            allow!
          end
        end

        def suggestion_committee_action?
          return unless permission_action.subject == :suggestion_committee_member

          request = context.fetch(:request, nil)

          case permission_action.action
          when :index
            allow!
          when :approve
            toggle_allow(!request&.accepted?)
          when :revoke
            toggle_allow(!request&.rejected?)
          end
        end

        def suggestion_admin_user_action?
          return unless permission_action.subject == :suggestion

          case permission_action.action
          when :read
            toggle_allow(Decidim::Suggestions.print_enabled)
          when :publish
            toggle_allow(suggestion.validating?)
          when :unpublish
            toggle_allow(suggestion.published?)
          when :discard
            toggle_allow(suggestion.validating?)
          when :export_pdf_signatures
            toggle_allow(suggestion.published? || suggestion.accepted? || suggestion.rejected?)
          when :export_votes
            toggle_allow(suggestion.offline_signature_type? || suggestion.any_signature_type?)
          when :accept
            allowed = suggestion.published? &&
                      suggestion.signature_end_date < Date.current &&
                      suggestion.percentage >= 100
            toggle_allow(allowed)
          when :reject
            allowed = suggestion.published? &&
                      suggestion.signature_end_date < Date.current &&
                      suggestion.percentage < 100
            toggle_allow(allowed)
          when :send_to_technical_validation
            toggle_allow(allowed_to_send_to_technical_validation?)
          else
            allow!
          end
        end

        def suggestion_export_action?
          allow! if permission_action.subject == :suggestions && permission_action.action == :export
        end

        def moderator_action?
          return unless permission_action.subject == :moderation

          allow!
        end

        def read_suggestion_list_action?
          return unless permission_action.subject == :suggestion &&
                        permission_action.action == :list

          allow!
        end

        def suggestion_user_action?
          return unless permission_action.subject == :suggestion

          case permission_action.action
          when :read
            toggle_allow(Decidim::Suggestions.print_enabled)
          when :preview, :edit
            allow!
          when :update
            toggle_allow(suggestion.created?)
          when :send_to_technical_validation
            toggle_allow(allowed_to_send_to_technical_validation?)
          when :manage_membership
            toggle_allow(suggestion.promoting_committee_enabled?)
          else
            disallow!
          end
        end

        def allowed_to_send_to_technical_validation?
          suggestion.created? && (
            !suggestion.created_by_individual? ||
            suggestion.enough_committee_members?
          )
        end
      end
    end
  end
end
