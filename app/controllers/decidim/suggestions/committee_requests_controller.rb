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

        form = Decidim::Suggestions::CommitteeMemberForm
               .from_params(suggestion_id: current_suggestion.id, user_id: current_user.id, state: "requested")

        SpawnCommitteeRequest.call(form, current_user) do
          on(:ok) do
            redirect_to suggestions_path, flash: {
              notice: I18n.t(
                "success",
                scope: %w(decidim suggestions committee_requests spawn)
              )
            }
          end

          on(:invalid) do |request|
            redirect_to suggestions_path, flash: {
              error: request.errors.full_messages.to_sentence
            }
          end
        end
      end
    end
  end
end
