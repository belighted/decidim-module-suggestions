# frozen_string_literal: true

module Decidim
  module Suggestions
    # Class uses to retrieve suggestions that have been a long time in
    # validating state
    class OutdatedValidatingSuggestions < Rectify::Query
      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # period_length - Maximum time in validating state
      def self.for(period_length)
        new(period_length).query
      end

      # Initializes the class.
      #
      # period_length - Maximum time in validating state
      def initialize(period_length)
        @period_length = Time.current - period_length
      end

      # Retrieves the available suggestion types for the given organization.
      def query
        Decidim::Suggestion
          .where(state: "validating")
          .where("updated_at < ?", @period_length)
      end
    end
  end
end
