# frozen_string_literal: true

module Decidim
  module Suggestions
    # Class uses to retrieve the suggestions created by the given user.
    class SuggestionsCreated < Rectify::Query
      attr_reader :user

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # user - Decidim::User
      def self.by(user)
        new(user).query
      end

      # Initializes the class.
      #
      # user: Decidim::User
      def initialize(user)
        @user = user
      end

      # Retrieves the suggestions created by the given user
      def query
        Suggestion.where(author: user)
      end
    end
  end
end
