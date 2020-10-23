# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller used to manage the available suggestion type scopes
      class SuggestionsTypeScopesController < Decidim::Suggestions::Admin::ApplicationController
        helper_method :current_suggestion_type_scope

        # GET /admin/suggestions_types/:suggestions_type_id/suggestions_type_scopes/new
        def new
          enforce_permission_to :create, :suggestion_type_scope
          @form = suggestion_type_scope_form.instance
        end

        # POST /admin/suggestions_types/:suggestions_type_id/suggestions_type_scopes
        def create
          enforce_permission_to :create, :suggestion_type_scope
          @form = suggestion_type_scope_form
                  .from_params(params, type_id: params[:suggestions_type_id])

          CreateSuggestionTypeScope.call(@form) do
            on(:ok) do |suggestion_type_scope|
              flash[:notice] = I18n.t("decidim.suggestions.admin.suggestions_type_scopes.create.success")
              redirect_to edit_suggestions_type_path(suggestion_type_scope.type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.suggestions.admin.suggestions_type_scopes.create.error")
              render :new
            end
          end
        end

        # GET /admin/suggestions_types/:suggestions_type_id/suggestions_type_scopes/:id/edit
        def edit
          enforce_permission_to :edit, :suggestion_type_scope, suggestion_type_scope: current_suggestion_type_scope
          @form = suggestion_type_scope_form.from_model(current_suggestion_type_scope)
        end

        # PUT /admin/suggestions_types/:suggestions_type_id/suggestions_type_scopes/:id
        def update
          enforce_permission_to :update, :suggestion_type_scope, suggestion_type_scope: current_suggestion_type_scope
          @form = suggestion_type_scope_form.from_params(params)

          UpdateSuggestionTypeScope.call(current_suggestion_type_scope, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("decidim.suggestions.admin.suggestions_type_scopes.update.success")
              redirect_to edit_suggestions_type_path(suggestion_type_scope.type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.suggestions.admin.suggestions_type_scopes.update.error")
              render :edit
            end
          end
        end

        # DELETE /admin/suggestions_types/:suggestions_type_id/suggestions_type_scopes/:id
        def destroy
          enforce_permission_to :destroy, :suggestion_type_scope, suggestion_type_scope: current_suggestion_type_scope
          current_suggestion_type_scope.destroy!

          redirect_to edit_suggestions_type_path(current_suggestion_type_scope.type), flash: {
            notice: I18n.t("decidim.suggestions.admin.suggestions_type_scopes.destroy.success")
          }
        end

        private

        def current_suggestion_type_scope
          @current_suggestion_type_scope ||= SuggestionsTypeScope.find(params[:id])
        end

        def suggestion_type_scope_form
          form(Decidim::Suggestions::Admin::SuggestionTypeScopeForm)
        end
      end
    end
  end
end
