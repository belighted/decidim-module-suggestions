# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Suggestions
    # Common logic to ordering resources
    module Orderable
      extend ActiveSupport::Concern

      included do
        include Decidim::Orderable

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= begin
            available_orders = %w(random recent most_voted most_commented recently_published)
            available_orders
          end
        end

        def default_order
          "random"
        end

        def reorder(suggestions)
          case order
          when "most_voted"
            suggestions.order_by_supports
          when "most_commented"
            suggestions.order_by_most_commented
          when "recent"
            suggestions.order_by_most_recent
          when "recently_published"
            suggestions.order_by_most_recently_published
          else
            suggestions.order_randomly(random_seed)
          end
        end
      end
    end
  end
end
