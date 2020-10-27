# frozen_string_literal: true

module Decidim
  module Suggestions
    # Exposes Suggestions versions so users can see how an Suggestion
    # has been updated through time.
    class VersionsController < Decidim::Suggestions::ApplicationController
      include ParticipatorySpaceContext
      participatory_space_layout
      helper SuggestionHelper

      include NeedsSuggestion
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        current_suggestion
      end
    end
  end
end
