# frozen_string_literal: true

module Decidim
  module Suggestions
    require "wicked"

    # Controller in charge of managing the create suggestion wizard.
    class CreateSuggestionController < Decidim::Suggestions::ApplicationController
      layout "layouts/decidim/suggestion_creation"

      include Wicked::Wizard
      include Decidim::FormFactory
      include SuggestionHelper
      include TypeSelectorOptions
      include SingleSuggestionType

      helper Decidim::Admin::IconLinkHelper
      helper SuggestionHelper
      helper_method :similar_suggestions
      helper_method :scopes
      helper_method :areas
      helper_method :current_suggestion
      helper_method :suggestion_type
      helper_method :promotal_committee_required?

      steps :select_suggestion_type,
            :previous_form,
            :show_similar_suggestions,
            :fill_data,
            :promotal_committee,
            :finish

      def show
        enforce_permission_to :create, :suggestion
        send("#{step}_step", suggestion: session_suggestion)
      end

      def update
        enforce_permission_to :create, :suggestion
        send("#{step}_step", params)
      end

      private

      def select_suggestion_type_step(_parameters)
        @form = form(Decidim::Suggestions::SelectSuggestionTypeForm).instance
        session[:suggestion] = {}

        if single_suggestion_type?
          redirect_to next_wizard_path
          return
        end

        @form = form(Decidim::Suggestions::SelectSuggestionTypeForm).instance
        render_wizard unless performed?
      end

      def previous_form_step(parameters)
        @form = build_form(Decidim::Suggestions::PreviousForm, parameters)
        render_wizard
      end

      def show_similar_suggestions_step(parameters)
        @form = build_form(Decidim::Suggestions::PreviousForm, parameters)
        unless @form.valid?
          redirect_to previous_wizard_path(validate_form: true)
          return
        end

        if similar_suggestions.empty?
          @form = build_form(Decidim::Suggestions::SuggestionForm, parameters)
          redirect_to wizard_path(:fill_data)
        end

        render_wizard unless performed?
      end

      def fill_data_step(parameters)
        @form = build_form(Decidim::Suggestions::SuggestionForm, parameters)
        @form.attachment = form(AttachmentForm).from_params({})

        render_wizard
      end

      def promotal_committee_step(parameters)
        @form = build_form(Decidim::Suggestions::SuggestionForm, parameters)
        unless @form.valid?
          redirect_to previous_wizard_path(validate_form: true)
          return
        end

        skip_step unless promotal_committee_required?

        if session_suggestion.has_key?(:id)
          render_wizard
          return
        end

        CreateSuggestion.call(@form, current_user) do
          on(:ok) do |suggestion|
            session[:suggestion][:id] = suggestion.id
            if current_suggestion.created_by_individual?
              render_wizard
            else
              redirect_to wizard_path(:finish)
            end
          end

          on(:invalid) do |suggestion|
            logger.fatal "Failed creating suggestion: #{suggestion.errors.full_messages.join(", ")}" if suggestion
            redirect_to previous_wizard_path(validate_form: true)
          end
        end
      end

      def finish_step(_parameters)
        render_wizard
      end

      def similar_suggestions
        @similar_suggestions ||= Decidim::Suggestions::SimilarSuggestions
                                 .for(current_organization, @form)
                                 .all
      end

      def build_form(klass, parameters)
        @form = if single_suggestion_type?
                  form(klass).from_params(parameters.merge(type_id: current_organization_suggestions_type.first.id), extra_context)
                else
                  form(klass).from_params(parameters, extra_context)
                end

        attributes = @form.attributes_with_values
        session[:suggestion] = session_suggestion.merge(attributes)
        @form.valid? if params[:validate_form]

        @form
      end

      def extra_context
        return {} unless suggestion_type_id

        { suggestion_type: suggestion_type }
      end

      def scopes
        @scopes ||= SuggestionsTypeScope.where(decidim_suggestions_types_id: @form.type_id)
      end

      def current_suggestion
        Suggestion.find(session_suggestion[:id]) if session_suggestion.has_key?(:id)
      end

      def suggestion_type
        @suggestion_type ||= SuggestionsType.find(suggestion_type_id)
      end

      def suggestion_type_id
        session_suggestion[:type_id] || @form&.type_id
      end

      def session_suggestion
        session[:suggestion] ||= {}
        session[:suggestion].with_indifferent_access
      end

      def promotal_committee_required?
        return false unless suggestion_type.promoting_committee_enabled?

        minimum_committee_members = suggestion_type.minimum_committee_members ||
                                    Decidim::Suggestions.minimum_committee_members
        minimum_committee_members.present? && minimum_committee_members.positive?
      end
    end
  end
end
