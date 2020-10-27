# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Suggestions
    # Common logic for elements that need to be able to select suggestion types.
    module TypeSelectorOptions
      extend ActiveSupport::Concern

      include Decidim::TranslationsHelper

      included do
        helper_method :available_suggestion_types, :suggestion_type_options,
                      :suggestion_types_each

        private

        # Return all suggestion types with scopes defined.
        def available_suggestion_types
          Decidim::Suggestions::SuggestionTypes
            .for(current_organization)
            .joins(:scopes)
            .distinct
        end

        def suggestion_type_options
          available_suggestion_types.map do |type|
            [type.title[I18n.locale.to_s], type.id]
          end
        end

        def suggestion_types_each
          available_suggestion_types.each do |type|
            yield(type)
          end
        end
      end
    end
  end
end
