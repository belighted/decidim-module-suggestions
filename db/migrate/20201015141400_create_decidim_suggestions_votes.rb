# frozen_string_literal: true

class CreateDecidimSuggestionsVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_suggestions_votes do |t|
      t.references :decidim_suggestion, null: false, index: true
      t.references :decidim_author, null: false, index: true
      t.integer :decidim_user_group_id, index: true

      t.index [:decidim_suggestion_id, :decidim_author_id, :decidim_user_group_id],
              unique: true,
              name: "decidim_suggestions_votes_author_uniqueness_index"

      t.text :encrypted_metadata
      t.string :timestamp
      t.string :hash_id, index: true

      t.timestamps
    end
  end
end
