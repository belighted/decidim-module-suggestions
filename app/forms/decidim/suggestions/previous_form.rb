# frozen_string_literal: true

module Decidim
  module Suggestions
    # A form object used to collect the title and description for an suggestion.
    class PreviousForm < Form
      include TranslatableAttributes

      mimic :suggestion

      attribute :title, String
      attribute :description, String
      attribute :type_id, Integer

      validates :title, :description, presence: true
      # validates :title, length: {maximum: 150}
      validates :description, length: {maximum: 4000}
      validates :type_id, presence: true
    end
  end
end
