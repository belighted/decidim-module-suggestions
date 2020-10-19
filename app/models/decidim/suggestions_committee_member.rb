# frozen_string_literal: true

module Decidim
  # Data store the committee members for the suggestion
  class SuggestionsCommitteeMember < ApplicationRecord
    belongs_to :suggestion,
               foreign_key: "decidim_suggestions_id",
               class_name: "Decidim::Suggestion",
               inverse_of: :committee_members

    belongs_to :user,
               foreign_key: "decidim_users_id",
               class_name: "Decidim::User"

    enum state: [:requested, :rejected, :accepted]

    validates :state, presence: true
    validates :user, uniqueness: { scope: :suggestion }

    scope :approved, -> { where(state: :accepted) }
    scope :non_deleted, -> { includes(:user).where(decidim_users: { deleted_at: nil }) }
    scope :excluding_author, -> { joins(:suggestion).where.not("decidim_users_id = decidim_author_id") }
  end
end
