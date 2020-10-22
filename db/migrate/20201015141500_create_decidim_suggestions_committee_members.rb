# frozen_string_literal: true

class CreateDecidimSuggestionsCommitteeMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_suggestions_committee_members do |t|
      t.references :decidim_suggestions, index: {
        name: "index_decidim_suggestions_committee_members_suggestion"
      }
      t.references :decidim_users, index: {
        name: "index_decidim_suggestions_committee_members_user"
      }
      t.integer :state, index: true, null: false, default: 0

      t.timestamps
    end
  end
end
