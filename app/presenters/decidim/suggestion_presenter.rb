# frozen_string_literal: true

module Decidim
  #
  # Decorator for suggestions
  #
  class SuggestionPresenter < SimpleDelegator
    def author
      @author ||= if user_group
                    Decidim::UserGroupPresenter.new(user_group)
                  else
                    Decidim::UserPresenter.new(super)
                  end
    end
  end
end
