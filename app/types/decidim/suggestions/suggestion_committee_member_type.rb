# frozen_string_literal: true

module Decidim
  module Suggestions
    # This type represents a suggestion committee member.
    SuggestionCommitteeMemberType = GraphQL::ObjectType.define do
      name "SuggestionCommitteeMemberType"
      description "A suggestion committee member"

      field :id, !types.ID, "Internal ID for this member of the committee"
      field :user, Decidim::Core::UserType, "The decidim user for this suggestion committee member"

      field :state, types.Int, "Type of the committee member"
      field :createdAt, Decidim::Core::DateTimeType, "The date this suggestion committee member was created", property: :created_at
      field :updatedAt, Decidim::Core::DateTimeType, "The date this suggestion committee member was updated", property: :updated_at
    end
  end
end
