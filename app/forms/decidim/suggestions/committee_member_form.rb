# frozen_string_literal: true

module Decidim
  module Suggestions
    # A form object used to collect the data for a new suggestion committee
    # member.
    class CommitteeMemberForm < Form
      mimic :suggestions_committee_member

      attribute :suggestion_id, Integer
      attribute :user_id, Integer
      attribute :state, String

      validates :suggestion_id, presence: true
      validates :user_id, presence: true
      validates :state, inclusion: { in: %w(requested rejected accepted) }, unless: :user_is_author?
      validates :state, inclusion: { in: %w(rejected accepted) }, if: :user_is_author?

      def user_is_author?
        suggestion&.decidim_author_id == user_id
      end

      private

      def suggestion
        @suggestion ||= Decidim::Suggestion.find_by(id: suggestion_id)
      end
    end
  end
end
