# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that creates a new suggestion type scope
      class CreateSuggestionTypeScope < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          suggestion_type_scope = create_suggestion_type_scope

          if suggestion_type_scope.persisted?
            broadcast(:ok, suggestion_type_scope)
          else
            suggestion_type_scope.errors.each do |attribute, error|
              form.errors.add(attribute, error)
            end

            broadcast(:invalid)
          end
        end

        private

        attr_reader :form

        def create_suggestion_type_scope
          suggestion_type = SuggestionsTypeScope.new(
            supports_required: form.supports_required,
            decidim_scopes_id: form.decidim_scopes_id,
            decidim_suggestions_types_id: form.context.type_id
          )

          return suggestion_type unless suggestion_type.valid?

          suggestion_type.save
          suggestion_type
        end
      end
    end
  end
end
