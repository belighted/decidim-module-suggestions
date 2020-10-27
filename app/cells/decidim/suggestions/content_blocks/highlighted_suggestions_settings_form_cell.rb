# frozen_string_literal: true

module Decidim
  module Suggestions
    module ContentBlocks
      class HighlightedSuggestionsSettingsFormCell < Decidim::ViewModel
        alias form model

        def content_block
          options[:content_block]
        end

        def label
          I18n.t("decidim.suggestions.admin.content_blocks.highlighted_suggestions.max_results")
        end
      end
    end
  end
end
