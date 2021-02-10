# frozen_string_literal: true

module Decidim
  module Suggestions
    # A command with all the business logic that creates a new suggestion.
    class CreateSuggestion < Rectify::Command
      include CurrentLocale
      include AttachmentMethods

      # Public: Initializes the command.
      #
      # form - A form object with the params.
      # current_user - Current user.
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if process_attachments?
          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        suggestion = create_suggestion

        if suggestion.persisted?
          broadcast(:ok, suggestion)
        else
          broadcast(:invalid, suggestion)
        end
      end

      private

      attr_reader :form, :current_user, :attachment

      # Creates the suggestion and all default components
      def create_suggestion
        suggestion = build_suggestion
        return suggestion unless suggestion.valid?

        suggestion.transaction do
          suggestion.save!
          @attached_to = suggestion
          create_attachment if process_attachments?
          create_components_for(suggestion)
          send_notification(suggestion)
          notify_admins(suggestion)
          add_author_as_follower(suggestion)
          add_author_as_committee_member(suggestion)
        end

        suggestion
      end

      def build_suggestion
        Suggestion.new(
          organization: form.current_organization,
          title: { current_locale => form.title },
          description: { current_locale => form.description },
          author: current_user,
          decidim_user_group_id: form.decidim_user_group_id,
          scoped_type: scoped_type,
          area: area,
          signature_type: form.signature_type,
          signature_end_date: signature_end_date,
          state: "created"
        )
      end

      def scoped_type
        SuggestionsTypeScope.find_by(
          decidim_suggestions_types_id: form.type_id,
          decidim_scopes_id: form.scope_id
        )
      end

      def signature_end_date
        return nil unless form.context.suggestion_type.custom_signature_end_date_enabled?

        form.signature_end_date
      end

      def area
        return nil unless form.context.suggestion_type.area_enabled?

        form.area
      end

      def create_components_for(suggestion)
        Decidim::Suggestions.default_components.each do |component_name|
          component = Decidim::Component.create!(
            name: Decidim::Components::Namer.new(suggestion.organization.available_locales, component_name).i18n_name,
            manifest_name: component_name,
            published_at: Time.current,
            participatory_space: suggestion
          )

          initialize_pages(component) if component_name == :pages
        end
      end

      def initialize_pages(component)
        Decidim::Pages::CreatePage.call(component) do
          on(:invalid) { raise "Can't create page" }
        end
      end

      def send_notification(suggestion)
        Decidim::EventsManager.publish(
          event: "decidim.events.suggestions.suggestion_created",
          event_class: Decidim::Suggestions::CreateSuggestionEvent,
          resource: suggestion,
          followers: suggestion.author.followers
        )
      end

      def notify_admins(suggestion)
        Decidim::EventsManager.publish(
          event: "decidim.events.suggestions.admin.suggestion_created",
          event_class: Decidim::Suggestions::Admin::CreateSuggestionEvent,
          resource: suggestion,
          affected_users: current_user.organization.admins.all,
          force_send: true
        )
      end

      def add_author_as_follower(suggestion)
        form = Decidim::FollowForm
               .from_params(followable_gid: suggestion.to_signed_global_id.to_s)
               .with_context(
                 current_organization: suggestion.organization,
                 current_user: current_user
               )

        Decidim::CreateFollow.new(form, current_user).call
      end

      def add_author_as_committee_member(suggestion)
        form = Decidim::Suggestions::CommitteeMemberForm
               .from_params(suggestion_id: suggestion.id, user_id: suggestion.decidim_author_id, state: "accepted")
               .with_context(
                 current_organization: suggestion.organization,
                 current_user: current_user
               )

        Decidim::Suggestions::SpawnCommitteeRequest.new(form, current_user).call
      end
    end
  end
end
