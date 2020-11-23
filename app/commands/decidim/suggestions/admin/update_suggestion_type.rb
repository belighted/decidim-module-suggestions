# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that updates an
      # existing suggestion type.
      class UpdateSuggestionType < Rectify::Command
        # Public: Initializes the command.
        #
        # suggestion_type: Decidim::SuggestionsType
        # form - A form object with the params.
        def initialize(suggestion_type, form)
          @form = form
          @suggestion_type = suggestion_type
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          suggestion_type.update(attributes)

          if suggestion_type.valid?
            upate_suggestions_signature_type
            broadcast(:ok, suggestion_type)
          else
            broadcast(:invalid)
          end
        end

        private

        attr_reader :form, :suggestion_type

        def attributes
          result = {
            title: form.title,
            description: form.description,
            signature_type: form.signature_type,
            attachments_enabled: form.attachments_enabled,
            comments_enabled: form.comments_enabled,
            undo_online_signatures_enabled: form.undo_online_signatures_enabled,
            custom_signature_end_date_enabled: form.custom_signature_end_date_enabled,
            area_enabled: form.area_enabled,
            promoting_committee_enabled: form.promoting_committee_enabled,
            minimum_committee_members: form.minimum_committee_members,
            collect_user_extra_fields: form.collect_user_extra_fields,
            extra_fields_legal_information: form.extra_fields_legal_information,
            validate_sms_code_on_votes: form.validate_sms_code_on_votes,
            document_number_authorization_handler: form.document_number_authorization_handler
          }

          result[:banner_image] = form.banner_image unless form.banner_image.nil?
          result
        end

        def upate_suggestions_signature_type
          suggestion_type.suggestions.signature_type_updatable.each do |suggestion|
            suggestion.update!(signature_type: suggestion_type.signature_type)
          end
        end
      end
    end
  end
end
