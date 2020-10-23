# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A command with all the business logic that creates a new suggestion type
      class CreateSuggestionType < Rectify::Command
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

          suggestion_type = create_suggestion_type

          if suggestion_type.persisted?
            broadcast(:ok, suggestion_type)
          else
            form.errors.add(:banner_image, suggestion_type.errors[:banner_image]) if suggestion_type.errors.include? :banner_image
            broadcast(:invalid)
          end
        end

        private

        attr_reader :form

        def create_suggestion_type
          suggestion_type = SuggestionsType.new(
            organization: form.current_organization,
            title: form.title,
            description: form.description,
            signature_type: form.signature_type,
            attachments_enabled: form.attachments_enabled,
            undo_online_signatures_enabled: form.undo_online_signatures_enabled,
            custom_signature_end_date_enabled: form.custom_signature_end_date_enabled,
            area_enabled: form.area_enabled,
            promoting_committee_enabled: form.promoting_committee_enabled,
            minimum_committee_members: form.minimum_committee_members,
            banner_image: form.banner_image,
            collect_user_extra_fields: form.collect_user_extra_fields,
            extra_fields_legal_information: form.extra_fields_legal_information,
            validate_sms_code_on_votes: form.validate_sms_code_on_votes,
            document_number_authorization_handler: form.document_number_authorization_handler
          )

          return suggestion_type unless suggestion_type.valid?

          suggestion_type.save
          suggestion_type
        end
      end
    end
  end
end
