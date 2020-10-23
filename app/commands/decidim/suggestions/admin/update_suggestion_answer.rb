# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic to answer
      # suggestions.
      class UpdateSuggestionAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # suggestion   - Decidim::Suggestion
        # form         - A form object with the params.
        # current_user - Decidim::User
        def initialize(suggestion, form, current_user)
          @form = form
          @suggestion = suggestion
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          @suggestion = Decidim.traceability.update!(
            suggestion,
            current_user,
            attributes
          )
          notify_suggestion_is_extended if @notify_extended
          broadcast(:ok, suggestion)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid, suggestion)
        end

        private

        attr_reader :form, :suggestion, :current_user

        def attributes
          attrs = {
            answer: form.answer,
            answer_url: form.answer_url
          }

          attrs[:answered_at] = Time.current if form.answer.present?

          if form.signature_dates_required?
            attrs[:signature_start_date] = form.signature_start_date
            attrs[:signature_end_date] = form.signature_end_date

            if suggestion.published?
              @notify_extended = true if form.signature_end_date != suggestion.signature_end_date &&
                                         form.signature_end_date > suggestion.signature_end_date
            end
          end

          attrs
        end

        def notify_suggestion_is_extended
          Decidim::EventsManager.publish(
            event: "decidim.events.suggestions.suggestion_extended",
            event_class: Decidim::Suggestions::ExtendSuggestionEvent,
            resource: suggestion,
            followers: suggestion.followers - [suggestion.author]
          )
        end
      end
    end
  end
end
