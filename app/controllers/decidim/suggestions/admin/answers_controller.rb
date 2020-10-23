# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller used to manage the suggestions answers
      class AnswersController < Decidim::Suggestions::Admin::ApplicationController
        include Decidim::Suggestions::NeedsSuggestion

        helper Decidim::Suggestions::SuggestionHelper
        layout "decidim/admin/suggestions"

        # GET /admin/suggestions/:id/answer/edit
        def edit
          enforce_permission_to :answer, :suggestion, suggestion: current_suggestion
          @form = form(Decidim::Suggestions::Admin::SuggestionAnswerForm)
                  .from_model(
                    current_suggestion,
                    suggestion: current_suggestion
                  )
        end

        # PUT /admin/suggestions/:id/answer
        def update
          enforce_permission_to :answer, :suggestion, suggestion: current_suggestion

          params[:id] = params[:slug]
          @form = form(Decidim::Suggestions::Admin::SuggestionAnswerForm)
                  .from_params(params, suggestion: current_suggestion)

          UpdateSuggestionAnswer.call(current_suggestion, @form, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("suggestions.update.success", scope: "decidim.suggestions.admin")
              redirect_to suggestions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("suggestions.update.error", scope: "decidim.suggestions.admin")
              render :edit
            end
          end
        end
      end
    end
  end
end
