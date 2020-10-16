# frozen_string_literal: true

# Migration that creates the decidim_suggestions table
class CreateDecidimSuggestions < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_suggestions do |t|
      t.jsonb :title, null: false
      t.jsonb :description, null: false

      t.integer :decidim_organization_id,
                foreign_key: true,
                index: {
                  name: "index_decidim_suggestions_on_decidim_organization_id"
                }

      t.index :title, name: "decidim_suggestions_title_search"

      t.integer :decidim_author_id, null: false
      t.string :decidim_author_type, null: false
      t.index :decidim_suggestions,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_suggestions_on_decidim_author"

      t.datetime :published_at, index: true

      t.integer :state, null: false, default: 0
      t.integer :signature_type, null: false, default: 0
      t.date :signature_start_date
      t.date :signature_end_date
      t.jsonb :answer
      t.datetime :answered_at, index: true
      t.string :answer_url
      t.integer :suggestion_votes_count, null: false, default: 0

      t.integer :decidim_user_group_id, index: true
      t.integer :hashtag, unique: true

      t.integer :suggestion_supports_count, null: false, default: 0

      t.integer :scoped_type_id, index: true

      t.datetime :first_progress_notification_at, index: true
      t.datetime :second_progress_notification_at, index: true

      t.integer :offline_votes

      t.string :reference

      t.references :decidim_area, index: true


      t.timestamps
    end
  end
end
