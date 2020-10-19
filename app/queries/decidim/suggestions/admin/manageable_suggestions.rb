# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Class that retrieves manageable suggestions for the given user.
      # Regular users will get only their suggestions. Administrators will
      # retrieve all suggestions.
      class ManageableSuggestions < Rectify::Query
        # Syntactic sugar to initialize the class and return the queried objects
        #
        # user - Decidim::User
        def self.for(user)
          new(user).query
        end

        # Initializes the class.
        #
        # user - Decidim::User
        def initialize(user)
          @user = user
        end

        # Retrieves all suggestions / Suggestions created by the user.
        def query
          return Suggestion.where(organization: @user.organization) if @user.admin?

          Suggestion.where(id: SuggestionsCreated.by(@user) + SuggestionsPromoted.by(@user))
        end
      end
    end
  end
end
