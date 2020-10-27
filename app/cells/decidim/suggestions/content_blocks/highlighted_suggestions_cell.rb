# frozen_string_literal: true

module Decidim
  module Suggestions
    module ContentBlocks
      class HighlightedSuggestionsCell < Decidim::ViewModel
        include Decidim::SanitizeHelper

        delegate :current_organization, to: :controller

        def show
          render if highlighted_suggestions.any?
        end

        def max_results
          model.settings.max_results
        end

        def highlighted_suggestions
          @highlighted_suggestions ||= OrganizationPrioritizedSuggestions
                                       .new(current_organization)
                                       .query
                                       .limit(max_results)
        end

        def i18n_scope
          "decidim.suggestions.pages.home.highlighted_suggestions"
        end

        def decidim_suggestions
          Decidim::Suggestions::Engine.routes.url_helpers
        end
      end
    end
  end
end
