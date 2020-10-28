# frozen_string_literal: true

class CreateDecidimSuggestionsTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_suggestions_types do |t|
      t.jsonb :title, null: false
      t.jsonb :description, null: false

      t.integer :decidim_organization_id,
                foreign_key: true,
                index: {
                  name: "index_decidim_suggestions_types_on_decidim_organization_id"
                }

      t.timestamps

      t.string :banner_image
      t.boolean :collect_user_extra_fields, default: false
      t.jsonb :extra_fields_legal_information
      t.integer :minimum_committee_members
      t.boolean :validate_sms_code_on_votes, default: false
      t.string :document_number_authorization_handler
      t.boolean :undo_online_signatures_enabled, default: true, null: false
      t.boolean :promoting_committee_enabled, default: true, null: false
      t.integer :signature_type, default: 0, null: false
      t.boolean :comments_enabled, default: true, null: false
      t.boolean :child_scope_threshold_enabled, default: false, null: false
      t.boolean :only_global_scope_enabled, default: false, null: false
      t.boolean :custom_signature_end_date_enabled, default: false, null: false
      t.boolean :area_enabled, default: false, null: false
      t.boolean :attachments_enabled, default: false, null: false
    end
  end
end
