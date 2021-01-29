# frozen_string_literal: true

class AddSuggestionsSettingsToDecidimOrganizations < ActiveRecord::Migration[5.2]
  def change
    unless column_exists? :decidim_organizations, :suggestions_settings
      add_column :decidim_organizations, :suggestions_settings, :jsonb
    end
  end
end
