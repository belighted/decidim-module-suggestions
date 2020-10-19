# frozen_string_literal: true

module Decidim
  module Suggestions
    # This type represents a Suggestion.
    SuggestionType = GraphQL::ObjectType.define do
      interfaces [
        -> { Decidim::Core::ParticipatorySpaceInterface },
        -> { Decidim::Core::ScopableInterface },
        -> { Decidim::Core::AttachableInterface },
        -> { Decidim::Core::AuthorInterface },
        -> { Decidim::Suggestions::SuggestionTypeInterface }
      ]

      name "Suggestion"
      description "A suggestion"

      field :description, Decidim::Core::TranslatedFieldType, "The description of this suggestion."
      field :slug, !types.String
      field :hashtag, types.String, "The hashtag for this suggestion"
      field :createdAt, !Decidim::Core::DateTimeType, "The time this suggestion was created", property: :created_at
      field :updatedAt, !Decidim::Core::DateTimeType, "The time this suggestion was updated", property: :updated_at
      field :publishedAt, !Decidim::Core::DateTimeType, "The time this suggestion was published", property: :published_at
      field :reference, !types.String, "Reference prefix for this suggestion"
      field :state, types.String, "Current status of the suggestion"
      field :signatureType, types.String, "Signature type of the suggestion", property: :signature_type
      field :signatureStartDate, !Decidim::Core::DateType, "The signature start date", property: :signature_start_date
      field :signatureEndDate, !Decidim::Core::DateType, "The signature end date", property: :signature_end_date
      field :offlineVotes, types.Int, "The number of offline votes in this suggestion", property: :offline_votes
      field :suggestionVotesCount, types.Int, "The number of votes in this suggestion", property: :suggestion_votes_count
      field :suggestionSupportsCount, types.Int, "The number of supports in this suggestion", property: :suggestion_supports_count

      field :author, !Decidim::Core::AuthorInterface, "The suggestion author" do
        resolve lambda { |obj, _args, _ctx|
          obj.user_group || obj.author
        }
      end

      field :committeeMembers, types[Decidim::Suggestions::SuggestionCommitteeMemberType], property: :committee_members
    end
  end
end
