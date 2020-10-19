# frozen_string_literal: true

module Decidim
  module Suggestions
    module AdminLog
      # This class holds the logic to present a `Decidim::Suggestion`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    SuggestionPresenter.new(action_log, view_helpers).present
      class SuggestionPresenter < Decidim::Log::BasePresenter
        private

        def action_string
          case action
          when "publish", "unpublish", "update", "send_to_technical_validation"
            "decidim.suggestions.admin_log.suggestion.#{action}"
          else
            super
          end
        end

        def diff_fields_mapping
          {
            state: :string,
            published_at: :date,
            signature_start_date: :date,
            signature_end_date: :date,
            description: :i18n,
            title: :i18n,
            hashtag: :string
          }
        end

        def i18n_labels_scope
          "activemodel.attributes.suggestions"
        end

        def has_diff?
          %w(publish unpublish send_to_technical_validation).include?(action) || super
        end
      end
    end
  end
end
