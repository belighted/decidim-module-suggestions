# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller that allows managing the Suggestion's Component
      # permissions in the admin panel.
      class ComponentPermissionsController < Decidim::Admin::ComponentPermissionsController
        include SuggestionAdmin
      end
    end
  end
end
