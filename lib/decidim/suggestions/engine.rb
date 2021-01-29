# frozen_string_literal: true

require "rails"
require "active_support/all"
require "decidim/core"
require "decidim/suggestions/current_locale"
require "decidim/suggestions/suggestions_filter_form_builder"
require "decidim/suggestions/suggestion_slug"
require "decidim/suggestions/api"
require "decidim/suggestions/query_extensions"

module Decidim
  module Suggestions
    # Decidim"s Suggestions Rails Engine.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Suggestions

      routes do
        get "/suggestion_types/search", to: "suggestion_types#search", as: :suggestion_types_search
        get "/suggestion_type_scopes/search", to: "suggestions_type_scopes#search", as: :suggestion_type_scopes_search
        get "/suggestion_type_signature_types/search", to: "suggestions_type_signature_types#search", as: :suggestion_type_signature_types_search

        resources :create_suggestion

        get "suggestions/:suggestion_id", to: redirect { |params, _request|
          suggestion = Decidim::Suggestion.find(params[:suggestion_id])
          suggestion ? "/suggestions/#{suggestion.slug}" : "/404"
        }, constraints: { suggestion_id: /[0-9]+/ }

        get "/suggestions/:suggestion_id/f/:component_id", to: redirect { |params, _request|
          suggestion = Decidim::Suggestion.find(params[:suggestion_id])
          suggestion ? "/suggestions/#{suggestion.slug}/f/#{params[:component_id]}" : "/404"
        }, constraints: { suggestion_id: /[0-9]+/ }

        resources :suggestions, param: :slug, only: [:index, :show], path: "suggestions" do
          resources :suggestion_signatures
          member do
            get :signature_identities
            get :authorization_sign_modal, to: "authorization_sign_modals#show"
          end

          resource :suggestion_vote, only: [:create, :destroy]
          resource :suggestion_widget, only: :show, path: "embed"
          resources :committee_requests, only: [:new], shallow: true do
            collection do
              get :spawn
            end
          end
          resources :versions, only: [:show, :index]
        end

        scope "/suggestions/:suggestion_slug/f/:component_id" do
          Decidim.component_manifests.each do |manifest|
            next unless manifest.engine

            constraints CurrentComponent.new(manifest) do
              mount manifest.engine, at: "/", as: "decidim_suggestion_#{manifest.name}"
            end
          end
        end
      end

      initializer "decidim_suggestions.assets" do |app|
        app.config.assets.precompile += %w(
          decidim_suggestions_manifest.js
          decidim_suggestions_manifest.css
        )
      end

      initializer "decidim_suggestions.content_blocks" do
        Decidim.content_blocks.register(:homepage, :highlighted_suggestions) do |content_block|
          content_block.cell = "decidim/suggestions/content_blocks/highlighted_suggestions"
          content_block.public_name_key = "decidim.suggestions.content_blocks.highlighted_suggestions.name"
          content_block.settings_form_cell = "decidim/suggestions/content_blocks/highlighted_suggestions_settings_form"

          content_block.settings do |settings|
            settings.attribute :max_results, type: :integer, default: 4
          end
        end
      end

      initializer "decidim_suggestions.extends" do
        Dir.glob("#{Decidim::Suggestions::Engine.root}/lib/extends/suggestions/**/*.rb").each do |override|
          require_dependency override
        end
      end

      initializer "decidim_suggestions.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Suggestions::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Suggestions::Engine.root}/app/views") # for partials
      end

      initializer "decidim_suggestions.menu" do
        Decidim.menu :menu do |menu|
          menu.item I18n.t("menu.suggestions", scope: "decidim"),
                    decidim_suggestions.suggestions_path,
                    position: 2.6,
                    active: :inclusive
        end
      end

      initializer "decidim_suggestions.badges" do
        Decidim::Gamification.register_badge(:suggestions) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            if model.is_a?(User)
              Decidim::Suggestion.where(
                author: model,
                user_group: nil
              ).published.count
            elsif model.is_a?(UserGroup)
              Decidim::Suggestion.where(
                user_group: model
              ).published.count
            end
          }
        end
      end

      initializer "decidim_suggestions.query_extensions" do
        Decidim::Api::QueryType.define do
          QueryExtensions.define(self)
        end
      end
    end
  end
end
