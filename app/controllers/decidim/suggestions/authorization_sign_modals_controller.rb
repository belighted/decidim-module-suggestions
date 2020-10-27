# frozen_string_literal: true

module Decidim
  module Suggestions
    class AuthorizationSignModalsController < Decidim::Suggestions::ApplicationController
      include Decidim::Suggestions::NeedsSuggestion

      helper_method :authorizations, :authorize_action_path
      layout false

      def show
        render template: "decidim/authorization_modals/show"
      end

      private

      def authorize_action_path(handler_name)
        authorizations.status_for(handler_name).current_path(redirect_url: URI(request.referer).path)
      end

      def authorizations
        @authorizations ||= action_authorized_to("vote", resource: current_suggestion, permissions_holder: current_suggestion.type)
      end
    end
  end
end
