# frozen_string_literal: true

module Decidim
  module Suggestions
    class ExportSuggestionsJob < ApplicationJob
      queue_as :default

      def perform(user, format)
        export_data = Decidim::Exporters.find_exporter(format).new(collection, serializer).export

        ExportMailer.export(user, "suggestions", export_data).deliver_now
      end

      private

      def collection
        Decidim::Suggestion.all
      end

      def serializer
        Decidim::Suggestions::SuggestionSerializer
      end
    end
  end
end
