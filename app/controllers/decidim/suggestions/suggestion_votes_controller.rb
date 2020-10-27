# frozen_string_literal: true

module Decidim
  module Suggestions
    # Exposes the suggestion vote resource so users can vote suggestions.
    class SuggestionVotesController < Decidim::Suggestions::ApplicationController
      include Decidim::Suggestions::NeedsSuggestion
      include Decidim::FormFactory

      before_action :authenticate_user!

      helper SuggestionHelper

      # POST /suggestions/:suggestion_id/suggestion_vote
      def create
        enforce_permission_to :vote, :suggestion, suggestion: current_suggestion, group_id: params[:group_id]
        @form = form(Decidim::Suggestions::VoteForm).from_params(suggestion_id: current_suggestion.id, author_id: current_user.id, group_id: params[:group_id])
        VoteSuggestion.call(@form, current_user) do
          on(:ok) do
            current_suggestion.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: {
              error: I18n.t("suggestion_votes.create.error", scope: "decidim.suggestions")
            }, status: :unprocessable_entity
          end
        end
      end

      # DELETE /suggestions/:suggestion_id/suggestion_vote
      def destroy
        enforce_permission_to :unvote, :suggestion, suggestion: current_suggestion, group_id: params[:group_id]
        UnvoteSuggestion.call(current_suggestion, current_user, params[:group_id]) do
          on(:ok) do
            current_suggestion.reload
            render :update_buttons_and_counters
          end
        end
      end
    end
  end
end
