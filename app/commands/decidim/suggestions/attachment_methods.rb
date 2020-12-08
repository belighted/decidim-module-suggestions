# frozen_string_literal: true

module Decidim
  module Suggestions
    module AttachmentMethods
      include Decidim::Suggestions::CurrentLocale

      private

      def build_attachment
        @attachment = Attachment.new(
          title: {current_locale => @form.attachment.title},
          file: @form.attachment.file,
          attached_to: @attached_to
        )
      end

      def attachment_invalid?
        if attachment.invalid? && attachment.errors.has_key?(:file)
          @form.attachment.errors.add :file, attachment.errors[:file]
          true
        end
      end

      def create_attachment
        attachment.attached_to = @attached_to
        attachment.save!
      end

      def process_attachments?
        @form.attachment && @form.attachment.file.present?
      end
    end
  end
end
