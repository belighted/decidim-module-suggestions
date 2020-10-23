# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller in charge of managing committee membership
      class CommitteeRequestsController < Decidim::Suggestions::Admin::ApplicationController
        include SuggestionAdmin

        # GET /admin/suggestions/:suggestion_id/committee_requests
        def index
          enforce_permission_to :index, :suggestion_committee_member
        end

        # GET /suggestions/:suggestion_id/committee_requests/:id/approve
        def approve
          enforce_permission_to :approve, :suggestion_committee_member, request: membership_request
          membership_request.accepted!

          redirect_to suggestion_committee_requests_path(membership_request.suggestion)
        end

        # DELETE /suggestions/:suggestion_id/committee_requests/:id/revoke
        def revoke
          enforce_permission_to :revoke, :suggestion_committee_member, request: membership_request
          membership_request.rejected!
          redirect_to suggestion_committee_requests_path(membership_request.suggestion)
        end

        private

        def membership_request
          @membership_request ||= SuggestionsCommitteeMember.find(params[:id])
        end
      end
    end
  end
end
