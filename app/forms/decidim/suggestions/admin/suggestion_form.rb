# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A form object used to show the suggestion data in the administration
      # panel.
      class SuggestionForm < Form
        include TranslatableAttributes

        mimic :suggestion

        translatable_attribute :title, String
        translatable_attribute :description, String
        attribute :type_id, Integer
        attribute :decidim_scope_id, Integer
        attribute :area_id, Integer
        attribute :signature_type, String
        attribute :signature_start_date, Decidim::Attributes::LocalizedDate
        attribute :signature_end_date, Decidim::Attributes::LocalizedDate
        attribute :hashtag, String
        attribute :offline_votes, Integer
        attribute :state, String
        attribute :attachment, AttachmentForm

        validates :title, :description, presence: true
        validates :area, presence: true, if: ->(form) { form.area_id.present? }
        validates :signature_type, presence: true, if: :signature_type_updatable?
        validates :signature_start_date, presence: true, if: ->(form) { form.context.suggestion.published? }
        validates :signature_end_date, presence: true, if: ->(form) { form.context.suggestion.published? }
        validates :signature_end_date, date: { after: :signature_start_date }, if: lambda { |form|
          form.signature_start_date.present? && form.signature_end_date.present?
        }
        validates :signature_end_date, date: { after: Date.current }, if: lambda { |form|
          form.signature_start_date.blank? && form.signature_end_date.present?
        }

        validates :offline_votes,
                  numericality: {
                    only_integer: true,
                    greater_than: 0
                  }, allow_blank: true

        validate :notify_missing_attachment_if_errored
        validate :area_is_not_removed

        def map_model(model)
          self.type_id = model.type.id
          self.decidim_scope_id = model.scope&.id
        end

        def signature_type_updatable?
          @signature_type_updatable ||= begin
                                          state ||= context.suggestion.state
                                          state == "validating" && context.current_user.admin? || state == "created"
                                        end
        end

        def state_updatable?
          false
        end

        def area_updatable?
          @area_updatable ||= current_user.admin? || context.suggestion.created?
        end

        def scoped_type_id
          return unless type && decidim_scope_id

          type.scopes.find_by!(decidim_scopes_id: decidim_scope_id).id
        end

        def area
          @area ||= current_organization.areas.find_by(id: area_id)
        end

        private

        def type
          @type ||= type_id ? Decidim::SuggestionsType.find(type_id) : context.suggestion.type
        end

        # This method will add an error to the `attachment` field only if there's
        # any error in any other field. This is needed because when the form has
        # an error, the attachment is lost, so we need a way to inform the user of
        # this problem.
        def notify_missing_attachment_if_errored
          errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present?
        end

        def area_is_not_removed
          return if context.suggestion.decidim_area_id.blank? || context.suggestion.created?

          errors.add(:area_id, :blank) if area_id.blank?
        end
      end
    end
  end
end
