# frozen_string_literal: true

module Decidim
  module Suggestions
    # Exposes the suggestion type text search so users can choose a type writing its name.
    class SuggestionsTypeScopesController < Decidim::Suggestions::ApplicationController
      helper_method :scoped_types

      # GET /suggestion_type_scopes/search
      def search
        enforce_permission_to :search, :suggestion_type_scope
        render layout: false
      end

      private

      def scoped_types
        @scoped_types ||= SuggestionsType.find(params[:type_id]).scopes
      end
    end
  end
end
