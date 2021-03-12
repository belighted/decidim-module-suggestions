# frozen-string_literal: true

module Decidim
  module Suggestions
    module Admin
      class VotesAmountMilestoneCompletedEvent < Decidim::Events::SimpleEvent
        include Rails.application.routes.mounted_helpers

        i18n_attributes :amount, :admin_suggestion_url, :admin_suggestion_path

        def admin_suggestion_path
          ResourceLocatorPresenter.new(resource).edit
        end

        def admin_suggestion_url
          decidim_admin_suggestions.edit_suggestion_url(resource, resource.mounted_params)
        end

        def amount
          extra[:amount]
        end

      end
    end
  end
end
