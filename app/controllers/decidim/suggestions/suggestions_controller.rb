# frozen_string_literal: true

module Decidim
  module Suggestions
    # This controller contains the logic regarding citizen suggestions
    class SuggestionsController < Decidim::Suggestions::ApplicationController
      include ParticipatorySpaceContext
      participatory_space_layout only: [:show]

      helper Decidim::WidgetUrlsHelper
      helper Decidim::AttachmentsHelper
      helper Decidim::FiltersHelper
      helper Decidim::OrdersHelper
      helper Decidim::ResourceHelper
      helper Decidim::IconHelper
      helper Decidim::Comments::CommentsHelper
      helper Decidim::Admin::IconLinkHelper
      helper Decidim::ResourceReferenceHelper
      helper PaginateHelper
      helper SuggestionHelper
      include SuggestionSlug

      include FilterResource
      include Paginable
      include Decidim::Suggestions::Orderable
      include TypeSelectorOptions
      include NeedsSuggestion
      include SingleSuggestionType

      helper_method :collection, :suggestions, :filter, :stats

      # GET /suggestions
      def index
        enforce_permission_to :list, :suggestion
      end

      # GET /suggestions/:id
      def show
        enforce_permission_to :read, :suggestion, suggestion: current_suggestion
      end

      # GET /suggestions/:id/signature_identities
      def signature_identities
        @voted_groups = SuggestionsVote
                        .supports
                        .where(suggestion: current_suggestion, author: current_user)
                        .pluck(:decidim_user_group_id)
        render layout: false
      end

      private

      alias current_suggestion current_participatory_space

      def current_participatory_space
        @current_participatory_space ||= Suggestion.find_by(id: id_from_slug(params[:slug]))
      end

      def suggestions
        @suggestions = search.results.includes(:scoped_type)
        @suggestions = reorder(@suggestions)
        @suggestions = paginate(@suggestions)
      end

      alias collection suggestions

      def search_klass
        SuggestionSearch
      end

      def default_filter_params
        {
          search_text: "",
          state: ["open"],
          type_id: default_filter_type_params,
          author: "any",
          scope_id: default_filter_scope_params,
          area_id: default_filter_area_params
        }
      end

      def default_filter_type_params
        %w(all) + Decidim::SuggestionsType.where(organization: current_organization).pluck(:id).map(&:to_s)
      end

      def default_filter_scope_params
        %w(all global) + current_organization.scopes.pluck(:id).map(&:to_s)
      end

      def default_filter_area_params
        %w(all) + current_organization.areas.pluck(:id).map(&:to_s)
      end

      def context_params
        {
          organization: current_organization,
          current_user: current_user
        }
      end

      def stats
        @stats ||= SuggestionStatsPresenter.new(suggestion: current_suggestion)
      end
    end
  end
end
