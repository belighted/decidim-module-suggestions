# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # Controller that allows managing all the attachments for an suggestion
      class SuggestionAttachmentsController < Decidim::Suggestions::Admin::ApplicationController
        include SuggestionAdmin
        include Decidim::Admin::Concerns::HasAttachments

        def after_destroy_path
          suggestion_attachments_path(current_suggestion)
        end

        def attached_to
          current_suggestion
        end
      end
    end
  end
end
