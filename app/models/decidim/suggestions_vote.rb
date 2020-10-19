# frozen_string_literal: true

require "digest/sha1"

module Decidim
  # Suggestions can be voted by users and supported by organizations.
  class SuggestionsVote < ApplicationRecord
    include Decidim::TranslatableAttributes

    belongs_to :author,
               foreign_key: "decidim_author_id",
               class_name: "Decidim::User"

    belongs_to :user_group,
               foreign_key: "decidim_user_group_id",
               class_name: "Decidim::UserGroup",
               optional: true

    belongs_to :suggestion,
               foreign_key: "decidim_suggestion_id",
               class_name: "Decidim::Suggestion",
               inverse_of: :votes

    validates :suggestion, uniqueness: { scope: [:author, :user_group] }

    after_commit :update_counter_cache, on: [:create, :destroy]

    scope :supports, -> { where.not(decidim_user_group_id: nil) }
    scope :votes, -> { where(decidim_user_group_id: nil) }

    # PUBLIC
    #
    # Generates a hashed representation of the suggestion support.
    def sha1
      return unless decidim_user_group_id.nil?

      title = translated_attribute(suggestion.title)
      description = translated_attribute(suggestion.description)

      Digest::SHA1.hexdigest "#{authorization_unique_id}#{title}#{description}"
    end

    private

    def authorization_unique_id
      first_authorization = Decidim::Suggestions::UserAuthorizations
                            .for(author)
                            .first

      first_authorization&.unique_id || author.email
    end

    def update_counter_cache
      suggestion.suggestion_votes_count = Decidim::SuggestionsVote
                                          .votes
                                          .where(decidim_suggestion_id: suggestion.id)
                                          .count

      suggestion.suggestion_supports_count = Decidim::SuggestionsVote
                                             .supports
                                             .where(decidim_suggestion_id: suggestion.id)
                                             .count

      suggestion.save
    end
  end
end
