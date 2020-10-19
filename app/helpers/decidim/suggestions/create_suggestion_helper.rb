# frozen_string_literal: true

module Decidim
  module Suggestions
    # Helper methods for the create suggestion wizard.
    module CreateSuggestionHelper
      def signature_type_options(suggestion_form)
        return all_signature_type_options unless suggestion_form.signature_type_updatable?

        type = ::Decidim::SuggestionsType.find(suggestion_form.type_id)
        allowed_signatures = type.allowed_signature_types_for_suggestions

        if allowed_signatures == %w(online)
          online_signature_type_options
        elsif allowed_signatures == %w(offline)
          offline_signature_type_options
        else
          all_signature_type_options
        end
      end

      private

      def online_signature_type_options
        [
          [
            I18n.t(
              "online",
              scope: %w(activemodel attributes suggestion signature_type_values)
            ), "online"
          ]
        ]
      end

      def offline_signature_type_options
        [
          [
            I18n.t(
              "offline",
              scope: %w(activemodel attributes suggestion signature_type_values)
            ), "offline"
          ]
        ]
      end

      def all_signature_type_options
        Suggestion.signature_types.keys.map do |type|
          [
            I18n.t(
              type,
              scope: %w(activemodel attributes suggestion signature_type_values)
            ), type
          ]
        end
      end
    end
  end
end
