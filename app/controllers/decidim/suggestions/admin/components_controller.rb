# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller that allows managing the Suggestion's Components in the
      # admin panel.
      class ComponentsController < Decidim::Admin::ComponentsController
        layout "decidim/admin/suggestion"

        include NeedsSuggestion
      end
    end
  end
end
