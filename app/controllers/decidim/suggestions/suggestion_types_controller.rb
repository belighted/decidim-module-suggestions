# frozen_string_literal: true

module Decidim
  module Suggestions
    # Exposes the suggestion type text search so users can choose a type writing its name.
    class SuggestionTypesController < Decidim::Suggestions::ApplicationController
      # GET /suggestion_types/search
      def search
        enforce_permission_to :search, :suggestion_type

        types = FreetextSuggestionTypes.for(current_organization, I18n.locale, params[:term])
        render json: { results: types.map { |type| { id: type.id.to_s, text: type.title[I18n.locale.to_s] } } }
      end
    end
  end
end
