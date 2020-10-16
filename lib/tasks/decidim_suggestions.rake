# frozen_string_literal: true

namespace :decidim_suggestions do
  desc "Check validating suggestions and moves all without changes for a configured time to discarded state"
  task check_validating: :environment do
    Decidim::Suggestions::OutdatedValidatingSuggestions
      .for(Decidim::Suggestions.max_time_in_validating_state)
      .each(&:discarded!)
  end

  desc "Check published suggestions and moves to accepted/rejected state depending on the votes collected when the signing period has finished"
  task check_published: :environment do
    Decidim::Suggestions::SupportPeriodFinishedSuggestions.new.each do |suggestion|
      supports_required = suggestion.scoped_type.supports_required

      if suggestion.suggestion_votes_count >= supports_required
        suggestion.accepted!
      else
        suggestion.rejected!
      end
    end
  end

  desc "Notify progress on published suggestions"
  task notify_progress: :environment do
    Decidim::Suggestion
      .published
      .where.not(first_progress_notification_at: nil)
      .where(second_progress_notification_at: nil).find_each do |suggestion|
      if suggestion.percentage >= Decidim::Suggestions.second_notification_percentage
        notifier = Decidim::Suggestions::ProgressNotifier.new(suggestion: suggestion)
        notifier.notify

        suggestion.second_progress_notification_at = Time.now.utc
        suggestion.save
      end
    end

    Decidim::Suggestion
      .published
      .where(first_progress_notification_at: nil).find_each do |suggestion|
      if suggestion.percentage >= Decidim::Suggestions.first_notification_percentage
        notifier = Decidim::Suggestions::ProgressNotifier.new(suggestion: suggestion)
        notifier.notify

        suggestion.first_progress_notification_at = Time.now.utc
        suggestion.save
      end
    end
  end
end
