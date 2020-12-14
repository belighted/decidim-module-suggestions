# frozen_string_literal: true

module Decidim
  module Suggestions
    # Controller in charge of managing committee membership
    class CommitteeRequestsController < Decidim::Suggestions::ApplicationController
      include Decidim::Suggestions::NeedsSuggestion

      helper SuggestionHelper
      helper Decidim::ActionAuthorizationHelper

      layout "layouts/decidim/application"

      # GET /suggestions/:suggestion_id/committee_requests/new
      def new
        enforce_permission_to :request_membership, :suggestion, suggestion: current_suggestion
      end

      # GET /suggestions/:suggestion_id/committee_requests/spawn
      def spawn
        enforce_permission_to :request_membership, :suggestion, suggestion: current_suggestion

        # Decision: To become a committee member, a user needs only the link and made a request.
        # No validation is needed by the admin or the suggestion creator in order for a committee member to vote.
        form = Decidim::Suggestions::CommitteeMemberForm
               .from_params(suggestion_id: current_suggestion.id, user_id: current_user.id, state: "accepted")

        SpawnCommitteeRequest.call(form, current_user) do
          on(:ok) do

            if current_suggestion.created? && current_suggestion.enough_committee_members?
              Admin::SendSuggestionToTechnicalValidation.call(current_suggestion, current_user)
            end

            redirect_to suggestion_path(current_suggestion.id), flash: {
              notice: I18n.t(
                "success",
                scope: %w(decidim suggestions committee_requests spawn)
              )
            }
          end

          on(:invalid) do |request|
            redirect_to suggestion_path(current_suggestion.id), flash: {
              error: request.errors.full_messages.to_sentence
            }
          end
        end
      end
    end
  end
end
