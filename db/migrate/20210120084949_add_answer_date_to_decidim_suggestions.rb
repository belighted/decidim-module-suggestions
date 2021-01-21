# frozen_string_literal: true

class AddAnswerDateToDecidimSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_suggestions, :answer_date, :date, null: true
  end
end
