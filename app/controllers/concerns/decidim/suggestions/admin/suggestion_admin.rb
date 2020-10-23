# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Suggestions
    module Admin
      # This concern is meant to be included in all controllers that are scoped
      # into an suggestion's admin panel. It will override the layout so it shows
      # the sidebar, preload the assembly, etc.
      module SuggestionAdmin
        extend ActiveSupport::Concern
        include SuggestionSlug

        included do
          include NeedsSuggestion

          include Decidim::Admin::ParticipatorySpaceAdminContext
          participatory_space_admin_layout

          alias_method :current_participatory_space, :current_suggestion
        end
      end
    end
  end
end
