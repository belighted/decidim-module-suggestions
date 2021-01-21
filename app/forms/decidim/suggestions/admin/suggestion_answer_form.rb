# frozen_string_literal: true

module Decidim
  module Suggestions
    module Admin
      # A form object used to manage the suggestion answer in the
      # administration panel.
      class SuggestionAnswerForm < Form
        include TranslatableAttributes

        mimic :suggestion

        attribute :state, String
        attribute :answer_date, Decidim::Attributes::LocalizedDate
        translatable_attribute :answer, String

        attribute :answer_url, String
        attribute :signature_start_date, Decidim::Attributes::LocalizedDate
        attribute :signature_end_date, Decidim::Attributes::LocalizedDate

        validates :state, presence: true
        validate :state_validation
        validates :answer_date, presence: true, if: :answer_date_allowed?
        validate :answer_date_restriction, if: :answer_date_allowed?
        validates :signature_start_date, :signature_end_date, presence: true, if: :signature_dates_required?
        validates :signature_end_date, date: { after: :signature_start_date }, if: lambda { |form|
          form.signature_start_date.present? && form.signature_end_date.present?
        }

        def signature_dates_required?
          @signature_dates_required ||= check_state
        end

        def state_updatable?
          manual_states.include? context.suggestion.state
        end

        def uniq_states
          (Decidim::Suggestion::AUTOMATIC_STATES + Decidim::Suggestion::MANUAL_STATES).uniq.map(&:to_s)
        end

        def manual_states
          Decidim::Suggestion::MANUAL_STATES.map(&:to_s)
        end

        def answer_date_allowed?
          return false if state == "published"

          state_updatable?
        end

        def state_validation
          errors.add(:state, :invalid) if !state_updatable? && context.suggestion.state != state
          errors.add(:state, :invalid) unless uniq_states.include? state
        end

        private

        def answer_date_restriction
          errors.add(:answer_date, I18n.t("must_be_before", scope: "errors.messages", date: I18n.localize(Date.current, format: :decidim_short))) unless answer_date <= Date.current
        end

        def check_state
          manual_states.include? context.suggestion.state
        end
      end
    end
  end
end
