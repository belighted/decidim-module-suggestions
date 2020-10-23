# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that updates an
      # existing suggestion.
      class UpdateSuggestion < Rectify::Command
        include Decidim::Suggestions::AttachmentMethods

        # Public: Initializes the command.
        #
        # suggestion - Decidim::Suggestion
        # form       - A form object with the params.
        def initialize(suggestion, form, current_user)
          @form = form
          @suggestion = suggestion
          @current_user = current_user
          @attached_to = suggestion
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @suggestion.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          @suggestion = Decidim.traceability.update!(
            suggestion,
            current_user,
            attributes
          )
          create_attachment if process_attachments?
          notify_suggestion_is_extended if @notify_extended
          broadcast(:ok, suggestion)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid, suggestion)
        end

        private

        attr_reader :form, :suggestion, :current_user, :attachment

        def attributes
          attrs = {
            title: form.title,
            description: form.description,
            hashtag: form.hashtag
          }

          if form.signature_type_updatable?
            attrs[:signature_type] = form.signature_type
            attrs[:scoped_type_id] = form.scoped_type_id if form.scoped_type_id
          end

          if current_user.admin?
            add_admin_accessible_attrs(attrs)
          elsif suggestion.created?
            attrs[:signature_end_date] = form.signature_end_date if suggestion.custom_signature_end_date_enabled?
            attrs[:decidim_area_id] = form.area_id if suggestion.area_enabled?
          end

          attrs
        end

        def add_admin_accessible_attrs(attrs)
          attrs[:signature_start_date] = form.signature_start_date
          attrs[:signature_end_date] = form.signature_end_date
          attrs[:offline_votes] = form.offline_votes if form.offline_votes
          attrs[:state] = form.state if form.state
          attrs[:decidim_area_id] = form.area_id

          if suggestion.published?
            @notify_extended = true if form.signature_end_date != suggestion.signature_end_date &&
                                       form.signature_end_date > suggestion.signature_end_date
          end
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
