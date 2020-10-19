# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A class used to find the admins for an suggestion.
      class AdminUsers < Rectify::Query
        # Syntactic sugar to initialize the class and return the queried objects.
        #
        # suggestion - Decidim::Suggestion
        def self.for(suggestion)
          new(suggestion).query
        end

        # Initializes the class.
        #
        # suggestion - Decidim::Suggestion
        def initialize(suggestion)
          @suggestion = suggestion
        end

        # Finds organization admins and the users with role admin for the given suggestion.
        #
        # Returns an ActiveRecord::Relation.
        def query
          Decidim::User.where(id: organization_admins)
        end

        private

        attr_reader :suggestion

        def organization_admins
          suggestion.organization.admins
        end
      end
    end
  end
end
