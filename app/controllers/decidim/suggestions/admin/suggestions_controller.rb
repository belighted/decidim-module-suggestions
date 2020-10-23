# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      require "csv"

      # Controller used to manage the suggestions
      class SuggestionsController < Decidim::Suggestions::Admin::ApplicationController
        include Decidim::Suggestions::NeedsSuggestion
        include Decidim::Suggestions::SingleSuggestionType
        include Decidim::Suggestions::TypeSelectorOptions
        include Decidim::Suggestions::Admin::Filterable

        helper Decidim::Suggestions::SuggestionHelper
        helper Decidim::Suggestions::CreateSuggestionHelper

        # GET /admin/suggestions
        def index
          enforce_permission_to :list, :suggestion
          @suggestions = filtered_collection
        end

        # GET /admin/suggestions/:id
        def show
          enforce_permission_to :read, :suggestion, suggestion: current_suggestion
        end

        # GET /admin/suggestions/:id/edit
        def edit
          enforce_permission_to :edit, :suggestion, suggestion: current_suggestion

          form_attachment_model = form(AttachmentForm).from_model(current_suggestion.attachments.first)
          @form = form(Decidim::Suggestions::Admin::SuggestionForm)
                  .from_model(
                    current_suggestion,
                    suggestion: current_suggestion
                  )
          @form.attachment = form_attachment_model

          render layout: "decidim/admin/suggestion"
        end

        # PUT /admin/suggestions/:id
        def update
          enforce_permission_to :update, :suggestion, suggestion: current_suggestion

          params[:id] = params[:slug]
          @form = form(Decidim::Suggestions::Admin::SuggestionForm)
                  .from_params(params, suggestion: current_suggestion)

          UpdateSuggestion.call(current_suggestion, @form, current_user) do
            on(:ok) do |suggestion|
              flash[:notice] = I18n.t("suggestions.update.success", scope: "decidim.suggestions.admin")
              redirect_to edit_suggestion_path(suggestion)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("suggestions.update.error", scope: "decidim.suggestions.admin")
              render :edit, layout: "decidim/admin/suggestion"
            end
          end
        end

        # POST /admin/suggestions/:id/publish
        def publish
          enforce_permission_to :publish, :suggestion, suggestion: current_suggestion

          PublishSuggestion.call(current_suggestion, current_user) do
            on(:ok) do
              redirect_to decidim_admin_suggestions.edit_suggestion_path(current_suggestion)
            end
          end
        end

        # DELETE /admin/suggestions/:id/unpublish
        def unpublish
          enforce_permission_to :unpublish, :suggestion, suggestion: current_suggestion

          UnpublishSuggestion.call(current_suggestion, current_user) do
            on(:ok) do
              redirect_to decidim_admin_suggestions.edit_suggestion_path(current_suggestion)
            end
          end
        end

        # DELETE /admin/suggestions/:id/discard
        def discard
          enforce_permission_to :discard, :suggestion, suggestion: current_suggestion
          current_suggestion.discarded!
          redirect_to decidim_admin_suggestions.edit_suggestion_path(current_suggestion)
        end

        # POST /admin/suggestions/:id/accept
        def accept
          enforce_permission_to :accept, :suggestion, suggestion: current_suggestion
          current_suggestion.accepted!
          redirect_to decidim_admin_suggestions.edit_suggestion_path(current_suggestion)
        end

        # DELETE /admin/suggestions/:id/reject
        def reject
          enforce_permission_to :reject, :suggestion, suggestion: current_suggestion
          current_suggestion.rejected!
          redirect_to decidim_admin_suggestions.edit_suggestion_path(current_suggestion)
        end

        # GET /admin/suggestions/:id/send_to_technical_validation
        def send_to_technical_validation
          enforce_permission_to :send_to_technical_validation, :suggestion, suggestion: current_suggestion

          SendSuggestionToTechnicalValidation.call(current_suggestion, current_user) do
            on(:ok) do
              redirect_to EngineRouter.main_proxy(current_suggestion).suggestions_path(suggestion_slug: nil), flash: {
                notice: I18n.t(
                  "success",
                  scope: %w(decidim suggestions admin suggestions edit)
                )
              }
            end
          end
        end

        # GET /admin/suggestions/export
        def export
          enforce_permission_to :export, :suggestions

          Decidim::Suggestions::ExportSuggestionsJob.perform_later(current_user, params[:format] || default_format)

          flash[:notice] = t("decidim.admin.exports.notice")

          redirect_back(fallback_location: suggestions_path)
        end

        # GET /admin/suggestions/:id/export_votes
        def export_votes
          enforce_permission_to :export_votes, :suggestion, suggestion: current_suggestion

          votes = current_suggestion.votes.votes.map(&:sha1)
          csv_data = CSV.generate(headers: false) do |csv|
            votes.each do |sha1|
              csv << [sha1]
            end
          end

          respond_to do |format|
            format.csv { send_data csv_data, file_name: "votes.csv" }
          end
        end

        # GET /admin/suggestions/:id/export_pdf_signatures.pdf
        def export_pdf_signatures
          enforce_permission_to :export_pdf_signatures, :suggestion, suggestion: current_suggestion

          @votes = current_suggestion.votes.votes

          output = render_to_string(
            pdf: "votes_#{current_suggestion.id}",
            layout: "decidim/admin/suggestions_votes",
            template: "decidim/suggestions/admin/suggestions/export_pdf_signatures.pdf.erb"
          )
          output = pdf_signature_service.new(pdf: output).signed_pdf if pdf_signature_service

          respond_to do |format|
            format.pdf do
              send_data(output, filename: "votes_#{current_suggestion.id}.pdf", type: "application/pdf")
            end
          end
        end

        private

        def collection
          @collection ||= ManageableSuggestions.for(current_user)
        end

        def pdf_signature_service
          @pdf_signature_service ||= Decidim.pdf_signature_service.to_s.safe_constantize
        end

        def default_format
          "json"
        end
      end
    end
  end
end
