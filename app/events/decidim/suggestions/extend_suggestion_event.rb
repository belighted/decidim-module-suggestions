# frozen-string_literal: true

module Decidim
  module Suggestions
    class ExtendSuggestionEvent < Decidim::Events::SimpleEvent
      def participatory_space
        resource
      end
    end
  end
end
