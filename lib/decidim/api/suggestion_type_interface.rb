# frozen_string_literal: true

module Decidim
  module Suggestions
    # This interface represents a commentable object.
    SuggestionTypeInterface = GraphQL::InterfaceType.define do
      name "SuggestionTypeInterface"
      description "An interface that can be used in Suggestion objects."

      field :suggestionType, Decidim::Suggestions::SuggestionApiType, "The object's suggestion type", property: :type
    end
  end
end
