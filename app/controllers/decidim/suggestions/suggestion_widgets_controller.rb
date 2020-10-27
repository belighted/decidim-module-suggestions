# frozen_string_literal: true

module Decidim
  module Suggestions
    # This controller provides a widget that allows embedding the suggestion
    class SuggestionWidgetsController < Decidim::WidgetsController
      helper SuggestionsHelper
      helper PaginateHelper
      helper SuggestionHelper
      helper Decidim::Comments::CommentsHelper
      helper Decidim::Admin::IconLinkHelper

      include NeedsSuggestion

      private

      def model
        @model ||= current_suggestion
      end

      def current_participatory_space
        model
      end

      def iframe_url
        @iframe_url ||= suggestion_suggestion_widget_url(model)
      end
    end
  end
end
