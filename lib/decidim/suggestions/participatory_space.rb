# frozen_string_literal: true

Decidim.register_participatory_space(:suggestions) do |participatory_space|
  participatory_space.icon = "decidim/suggestions/icon.svg"
  participatory_space.stylesheet = "decidim/suggestions/suggestions"

  participatory_space.context(:public) do |context|
    context.engine = Decidim::Suggestions::Engine
    context.layout = "layouts/decidim/suggestion"
  end

  participatory_space.context(:admin) do |context|
    context.engine = Decidim::Suggestions::AdminEngine
    context.layout = "layouts/decidim/admin/suggestion"
  end

  participatory_space.participatory_spaces do |organization|
    Decidim::Suggestion.where(organization: organization)
  end

  participatory_space.query_type = "Decidim::Suggestions::SuggestionType"

  participatory_space.register_resource(:suggestion) do |resource|
    resource.model_class_name = "Decidim::Suggestion"
    resource.card = "decidim/suggestions/suggestion"
    resource.searchable = true
  end

  participatory_space.register_resource(:suggestions_type) do |resource|
    resource.model_class_name = "Decidim::SuggestionsType"
    resource.actions = %w(vote)
  end

  participatory_space.model_class_name = "Decidim::Suggestion"
  participatory_space.permissions_class_name = "Decidim::Suggestions::Permissions"

  participatory_space.exports :suggestions do |export|
    export.collection do
      Decidim::Suggestion
    end

    export.serializer Decidim::Suggestions::SuggestionSerializer
  end

  participatory_space.seeds do
    seeds_root = File.join(__dir__, "..", "..", "..", "db", "seeds")
    organization = Decidim::Organization.first

    Decidim::ContentBlock.create(
      organization: organization,
      weight: 33,
      scope_name: :homepage,
      manifest_name: :highlighted_suggestions,
      published_at: Time.current
    )

    3.times do |n|
      type = Decidim::SuggestionsType.create!(
        title: Decidim::Faker::Localized.sentence(5),
        description: Decidim::Faker::Localized.sentence(25),
        organization: organization,
        banner_image: File.new(File.join(seeds_root, "city2.jpeg"))
      )

      organization.top_scopes.each do |scope|
        Decidim::SuggestionsTypeScope.create(
          type: type,
          scope: scope,
          supports_required: (n + 1) * 1000
        )
      end
    end

    Decidim::Suggestion.states.keys.each do |state|
      Decidim::Suggestion.skip_callback(:save, :after, :notify_state_change, raise: false)
      Decidim::Suggestion.skip_callback(:create, :after, :notify_creation, raise: false)

      params = {
        title: Decidim::Faker::Localized.sentence(3),
        description: Decidim::Faker::Localized.sentence(25),
        scoped_type: Decidim::SuggestionsTypeScope.reorder(Arel.sql("RANDOM()")).first,
        state: state,
        signature_type: "online",
        signature_start_date: Date.current - 7.days,
        signature_end_date: Date.current + 7.days,
        published_at: Time.current - 7.days,
        author: Decidim::User.reorder(Arel.sql("RANDOM()")).first,
        organization: organization
      }

      suggestion = Decidim.traceability.perform_action!(
        "publish",
        Decidim::Suggestion,
        organization.users.first,
        visibility: "all"
      ) do
        Decidim::Suggestion.create!(params)
      end
      suggestion.add_to_index_as_search_resource

      Decidim::Comments::Seed.comments_for(suggestion)

      Decidim::Suggestions.default_components.each do |component_name|
        component = Decidim::Component.create!(
          name: Decidim::Components::Namer.new(suggestion.organization.available_locales, component_name).i18n_name,
          manifest_name: component_name,
          published_at: Time.current,
          participatory_space: suggestion
        )

        next unless component_name == :pages

        Decidim::Pages::CreatePage.call(component) do
          on(:invalid) { raise "Can't create page" }
        end
      end
    end
  end
end
