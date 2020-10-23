# frozen_string_literal: true

require_dependency "decidim/suggestions/admin/application_controller"

module Decidim
  module Suggestions
    module Admin
      # Controller used to manage the available suggestion types for the current
      # organization.
      class SuggestionsTypesController < Decidim::Suggestions::Admin::ApplicationController
        helper ::Decidim::Admin::ResourcePermissionsHelper
        helper_method :current_suggestion_type

        # GET /admin/suggestions_types
        def index
          enforce_permission_to :index, :suggestion_type

          @suggestions_types = SuggestionTypes.for(current_organization)
        end

        # GET /admin/suggestions_types/new
        def new
          enforce_permission_to :create, :suggestion_type
          @form = suggestion_type_form.instance
        end

        # POST /admin/suggestions_types
        def create
          enforce_permission_to :create, :suggestion_type
          @form = suggestion_type_form.from_params(params)

          CreateSuggestionType.call(@form) do
            on(:ok) do |suggestion_type|
              flash[:notice] = I18n.t("decidim.suggestions.admin.suggestions_types.create.success")
              redirect_to edit_suggestions_type_path(suggestion_type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.suggestions.admin.suggestions_types.create.error")
              render :new
            end
          end
        end

        # GET /admin/suggestions_types/:id/edit
        def edit
          enforce_permission_to :edit, :suggestion_type, suggestion_type: current_suggestion_type
          @form = suggestion_type_form
                  .from_model(current_suggestion_type,
                              suggestion_type: current_suggestion_type)
        end

        # PUT /admin/suggestions_types/:id
        def update
          enforce_permission_to :update, :suggestion_type, suggestion_type: current_suggestion_type

          @form = suggestion_type_form
                  .from_params(params, suggestion_type: current_suggestion_type)

          UpdateSuggestionType.call(current_suggestion_type, @form) do
            on(:ok) do
              flash[:notice] = I18n.t("decidim.suggestions.admin.suggestions_types.update.success")
              redirect_to edit_suggestions_type_path(current_suggestion_type)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("decidim.suggestions.admin.suggestions_types.update.error")
              render :edit
            end
          end
        end

        # DELETE /admin/suggestions_types/:id
        def destroy
          enforce_permission_to :destroy, :suggestion_type, suggestion_type: current_suggestion_type
          current_suggestion_type.destroy!

          redirect_to suggestions_types_path, flash: {
            notice: I18n.t("decidim.suggestions.admin.suggestions_types.destroy.success")
          }
        end

        private

        def current_suggestion_type
          @current_suggestion_type ||= SuggestionsType.find(params[:id])
        end

        def suggestion_type_form
          form(Decidim::Suggestions::Admin::SuggestionTypeForm)
        end
      end
    end
  end
end
