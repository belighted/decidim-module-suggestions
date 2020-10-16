# frozen_string_literal: true

module Decidim
  module Suggestions
    # This module's job is to extend the API with custom fields related to
    # decidim-suggestions.
    module QueryExtensions
      # Public: Extends a type with `decidim-suggestions`'s fields.
      #
      # type - A GraphQL::BaseType to extend.
      #
      # Returns nothing.
      def self.define(type)
        type.field :suggestionsTypes do
          type !types[SuggestionApiType]
          description "Lists all suggestion types"

          resolve lambda { |_obj, _args, ctx|
            Decidim::SuggestionsType.where(
              organization: ctx[:current_organization]
            )
          }
        end

        type.field :suggestionsType do
          type SuggestionApiType
          description "Finds a suggestion type"
          argument :id, !types.ID, "The ID of the suggestion type"

          resolve lambda { |_obj, args, ctx|
            Decidim::SuggestionsType.find_by(
              organization: ctx[:current_organization],
              id: args[:id]
            )
          }
        end
      end
    end
  end
end
