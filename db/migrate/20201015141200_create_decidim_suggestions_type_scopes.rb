# frozen_string_literal: true

class CreateDecidimSuggestionsTypeScopes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_suggestions_type_scopes do |t|
      t.references :decidim_suggestions_types, index: { name: "idx_scoped_suggestion_type_type" }
      t.references :decidim_scopes, index: { name: "idx_scoped_suggestion_type_scope" }
      t.integer :supports_required, null: false

      t.timestamps
    end
  end
end
