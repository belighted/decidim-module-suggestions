# frozen_string_literal: true

module Decidim
  module Suggestions
    require "wicked"

    class SuggestionSignaturesController < Decidim::Suggestions::ApplicationController
      layout "layouts/decidim/suggestion_signature_creation"

      include Wicked::Wizard
      include Decidim::Suggestions::NeedsSuggestion
      include Decidim::FormFactory

      prepend_before_action :set_wizard_steps
      before_action :authenticate_user!

      helper SuggestionHelper

      helper_method :suggestion_type, :extra_data_legal_information

      # GET /suggestions/:suggestion_id/suggestion_signatures/:step
      def show
        group_id = params[:group_id] || (session[:suggestion_vote_form] ||= {})["group_id"]
        enforce_permission_to :sign_suggestion, :suggestion, suggestion: current_suggestion, group_id: group_id, signature_has_steps: signature_has_steps?
        send("#{step}_step", suggestion_vote_form: session[:suggestion_vote_form])
      end

      # PUT /suggestions/:suggestion_id/suggestion_signatures/:step
      def update
        group_id = params.dig(:suggestions_vote, :group_id) || session[:suggestion_vote_form]["group_id"]
        enforce_permission_to :sign_suggestion, :suggestion, suggestion: current_suggestion, group_id: group_id, signature_has_steps: signature_has_steps?
        send("#{step}_step", params)
      end

      # POST /suggestions/:suggestion_id/suggestion_signatures
      def create
        # When it is not published yet we need users to do both - become a committee member and sign at once
        if current_suggestion.created? &&
          current_suggestion.promoting_committee_enabled? &&
          !current_suggestion.has_authorship?(current_user)
          # No validation is needed by the admin or the suggestion creator in order for a committee member to vote.
          enforce_permission_to :request_membership, :suggestion, suggestion: current_suggestion
          form = Decidim::Suggestions::CommitteeMemberForm.from_params(suggestion_id: current_suggestion.id, user_id: current_user.id, state: "accepted")

          SpawnCommitteeRequest.call(form, current_user) do
            on(:ok) do
              if current_suggestion.created? && current_suggestion.enough_committee_members?
                Admin::SendSuggestionToTechnicalValidation.call(current_suggestion, current_user)
              end
            end
            on(:invalid) do |request|
              redirect_to suggestion_path(current_suggestion.id), flash: {
                error: request.errors.full_messages.to_sentence
              } and return
            end
          end
        end

        group_id = params[:group_id] || session[:suggestion_vote_form]&.dig("group_id")
        enforce_permission_to :vote, :suggestion, suggestion: current_suggestion, group_id: group_id
        @form = form(Decidim::Suggestions::VoteForm)
                .from_params(
                  suggestion_id: current_suggestion.id,
                  author_id: current_user.id,
                  group_id: group_id
                )

        VoteSuggestion.call(@form, current_user) do
          on(:ok) do
            current_suggestion.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: {
              error: I18n.t("create.error", scope: "decidim.suggestions.suggestion_votes")
            }, status: :unprocessable_entity
          end
        end
      end

      private

      def fill_personal_data_step(_unused)
        @form = form(Decidim::Suggestions::VoteForm)
                .from_params(
                  suggestion_id: current_suggestion.id,
                  author_id: current_user.id,
                  group_id: params[:group_id]
                )
        session[:suggestion_vote_form] = { group_id: @form.group_id }
        skip_step unless suggestion_type.collect_user_extra_fields
        render_wizard
      end

      def sms_phone_number_step(parameters)
        if parameters.has_key?(:suggestions_vote) || !fill_personal_data_step?
          build_vote_form(parameters)
        else
          check_session_personal_data
        end
        clear_session_sms_code

        if @vote_form.invalid?
          flash[:alert] = I18n.t("personal_data.invalid", scope: "decidim.suggestions.suggestion_votes")
          jump_to(previous_step)
        end

        @form = Decidim::Verifications::Sms::MobilePhoneForm.new
        render_wizard
      end

      def sms_code_step(parameters)
        check_session_personal_data if fill_personal_data_step?
        @phone_form = Decidim::Verifications::Sms::MobilePhoneForm.from_params(parameters.merge(user: current_user))
        @form = Decidim::Verifications::Sms::ConfirmationForm.new
        render_wizard && return if session_sms_code.present?

        ValidateMobilePhone.call(@phone_form, current_user) do
          on(:ok) do |metadata|
            store_session_sms_code(metadata)
            render_wizard
          end

          on(:invalid) do
            flash[:alert] = I18n.t("sms_phone.invalid", scope: "decidim.suggestions.suggestion_votes")
            redirect_to wizard_path(:sms_phone_number)
          end
        end
      end

      def finish_step(parameters)
        if parameters.has_key?(:suggestions_vote) || !fill_personal_data_step?
          build_vote_form(parameters)
        else
          check_session_personal_data
        end

        if sms_step?
          @confirmation_code_form = Decidim::Verifications::Sms::ConfirmationForm.from_params(parameters)

          ValidateSmsCode.call(@confirmation_code_form, session_sms_code) do
            on(:ok) { clear_session_sms_code }

            on(:invalid) do
              flash[:alert] = I18n.t("sms_code.invalid", scope: "decidim.suggestions.suggestion_votes")
              jump_to :sms_code
              render_wizard && return
            end
          end
        end

        VoteSuggestion.call(@vote_form, current_user) do
          on(:ok) do
            session[:suggestion_vote_form] = {}
          end

          on(:invalid) do |vote|
            logger.fatal "Failed creating signature: #{vote.errors.full_messages.join(", ")}" if vote
            flash[:alert] = I18n.t("create.invalid", scope: "decidim.suggestions.suggestion_votes")
            jump_to previous_step
          end
        end
        render_wizard
      end

      def build_vote_form(parameters)
        @vote_form = form(Decidim::Suggestions::VoteForm).from_params(parameters).tap do |form|
          form.suggestion_id = current_suggestion.id
          form.author_id = current_user.id
        end

        session[:suggestion_vote_form] = session[:suggestion_vote_form].merge(@vote_form.attributes_with_values)
      end

      def session_vote_form
        raw_birth_date = session[:suggestion_vote_form]["date_of_birth"]
        return unless raw_birth_date

        @vote_form = form(Decidim::Suggestions::VoteForm).from_params(
          session[:suggestion_vote_form].merge("date_of_birth" => Date.parse(raw_birth_date))
        )
      end

      def suggestion_type
        @suggestion_type ||= current_suggestion&.scoped_type&.type
      end

      def extra_data_legal_information
        @extra_data_legal_information ||= suggestion_type.extra_fields_legal_information
      end

      def check_session_personal_data
        return if session[:suggestion_vote_form].present? && session_vote_form&.valid?

        flash[:alert] = I18n.t("create.error", scope: "decidim.suggestions.suggestion_votes")
        jump_to(:fill_personal_data)
      end

      def store_session_sms_code(metadata)
        session[:suggestion_sms_code] = metadata
      end

      def session_sms_code
        session[:suggestion_sms_code]
      end

      def clear_session_sms_code
        session[:suggestion_sms_code] = {}
      end

      def sms_step?
        current_suggestion.validate_sms_code_on_votes?
      end

      def fill_personal_data_step?
        suggestion_type.collect_user_extra_fields?
      end

      def set_wizard_steps
        initial_wizard_steps = [:finish]
        initial_wizard_steps.unshift(:sms_phone_number, :sms_code) if sms_step?
        initial_wizard_steps.unshift(:fill_personal_data) if fill_personal_data_step?

        self.steps = initial_wizard_steps
      end
    end
  end
end
