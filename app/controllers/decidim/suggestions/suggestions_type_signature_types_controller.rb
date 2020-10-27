# frozen_string_literal: true

module Decidim
  module Suggestions
    class SuggestionsTypeSignatureTypesController < Decidim::Suggestions::ApplicationController
      helper_method :allowed_signature_types_for_suggestions

      # GET /suggestion_type_signature_types/search
      def search
        enforce_permission_to :search, :suggestion_type_signature_types
        render layout: false
      end

      private

      def allowed_signature_types_for_suggestions
        @allowed_signature_types_for_suggestions ||= SuggestionsType.find(params[:type_id]).allowed_signature_types_for_suggestions
      end
    end
  end
end
