# frozen-string_literal: true

module Decidim
  module Suggestions
    class VotesAmountMilestoneCompletedEvent < Decidim::Events::SimpleEvent
      i18n_attributes :amount

      def amount
        extra[:amount]
      end

    end
  end
end
