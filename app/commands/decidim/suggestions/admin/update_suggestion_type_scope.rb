# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that updates an
      # existing suggestion type scope.
      class UpdateSuggestionTypeScope < Rectify::Command
        # Public: Initializes the command.
        #
        # suggestion_type: Decidim::SuggestionsTypeScope
        # form - A form object with the params.
        def initialize(suggestion_type_scope, form)
          @form = form
          @suggestion_type_scope = suggestion_type_scope
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          suggestion_type_scope.update(attributes)
          broadcast(:ok, suggestion_type_scope)
        end

        private

        attr_reader :form, :suggestion_type_scope

        def attributes
          {
            supports_required: form.supports_required,
            decidim_scopes_id: form.decidim_scopes_id
          }
        end
      end
    end
  end
end
