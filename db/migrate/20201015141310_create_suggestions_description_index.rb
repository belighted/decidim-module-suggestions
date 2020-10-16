# frozen_string_literal: true

class CreateSuggestionsDescriptionIndex < ActiveRecord::Migration[5.1]
  def up
    execute "CREATE INDEX decidim_suggestions_description_search ON decidim_suggestions(md5(description::text))"
  end

  def down
    execute "DROP INDEX decidim_suggestions_description_search"
  end
end
