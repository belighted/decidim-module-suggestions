# frozen_string_literal: true

module Decidim
  # The data store for a Suggestion in the Decidim::Suggestions component.
  class Suggestion < ApplicationRecord
    include ActiveModel::Dirty
    include Decidim::Authorable
    include Decidim::Participable
    include Decidim::Publicable
    include Decidim::Scopable
    include Decidim::Comments::Commentable
    include Decidim::Followable
    include Decidim::HasAttachments
    include Decidim::HasAttachmentCollections
    include Decidim::Traceable
    include Decidim::Loggable
    include Decidim::Suggestions::SuggestionSlug
    include Decidim::Resourceable
    include Decidim::HasReference
    include Decidim::Randomable
    include Decidim::Searchable
    include Decidim::Suggestions::HasArea

    belongs_to :organization,
               foreign_key: "decidim_organization_id",
               class_name: "Decidim::Organization"

    belongs_to :scoped_type,
               foreign_key: "scoped_type_id",
               class_name: "Decidim::SuggestionsTypeScope",
               inverse_of: :suggestions

    delegate :type, :scope, :scope_name, to: :scoped_type, allow_nil: true
    delegate :attachments_enabled?, :promoting_committee_enabled?, :custom_signature_end_date_enabled?, :area_enabled?, to: :type
    delegate :name, to: :area, prefix: true, allow_nil: true

    has_many :votes,
             foreign_key: "decidim_suggestion_id",
             class_name: "Decidim::SuggestionsVote",
             dependent: :destroy,
             inverse_of: :suggestion

    has_many :committee_members,
             foreign_key: "decidim_suggestions_id",
             class_name: "Decidim::SuggestionsCommitteeMember",
             dependent: :destroy,
             inverse_of: :suggestion

    has_many :components, as: :participatory_space, dependent: :destroy

    # This relationship exists only by compatibility reasons.
    # Suggestions are not intended to have categories.
    has_many :categories,
             foreign_key: "decidim_participatory_space_id",
             foreign_type: "decidim_participatory_space_type",
             dependent: :destroy,
             as: :participatory_space

    enum signature_type: [:online, :offline, :any], _suffix: true
    AUTOMATIC_STATES = [:created, :validating, :discarded, :published, :rejected, :accepted].freeze
    MANUAL_STATES = [:published, :examinated, :debatted, :classified].freeze
    enum state: (AUTOMATIC_STATES + MANUAL_STATES).uniq

    validates :title, :description, :state, presence: true
    validates :signature_type, presence: true
    validate :signature_type_allowed

    validates :hashtag,
              uniqueness: true,
              allow_blank: true,
              case_sensitive: false

    scope :open, lambda {
      where.not(state: [:classified, :discarded, :rejected, :accepted, :created])
           .currently_signable
    }
    scope :closed, lambda {
      where(state: [:classified, :discarded, :rejected, :accepted])
        .or(currently_unsignable)
    }
    scope :published, -> { where.not(published_at: nil) }
    scope :with_state, ->(state) { where(state: state) if state.present? }

    scope :currently_signable, lambda {
      where("signature_start_date <= ?", Date.current)
        .where("signature_end_date >= ?", Date.current)
    }
    scope :currently_unsignable, lambda {
      where("signature_start_date > ?", Date.current)
        .or(where("signature_end_date < ?", Date.current))
    }

    scope :answered, -> { where.not(answered_at: nil) }

    scope :public_spaces, -> { published }
    scope :signature_type_updatable, -> { created }

    scope :order_by_answer_date, -> { order("answered_at DESC nulls last") }
    scope :order_by_most_recent, -> { order(created_at: :desc) }
    scope :order_by_most_recently_published, -> { order(published_at: :desc) }
    scope :order_by_supports, -> { order(Arel.sql("suggestion_votes_count + coalesce(offline_votes, 0) desc")) }
    scope :order_by_most_commented, lambda {
      select("decidim_suggestions.*")
        .left_joins(:comments)
        .group("decidim_suggestions.id")
        .order(Arel.sql("count(decidim_comments_comments.id) desc"))
    }

    after_save :notify_state_change
    after_create :notify_creation

    searchable_fields({
                        participatory_space: :itself,
                        A: :title,
                        D: :description,
                        datetime: :published_at
                      },
                      index_on_create: ->(_suggestion) { false },
                      # is Resourceable instead of ParticipatorySpaceResourceable so we can't use `visible?`
                      index_on_update: ->(suggestion) { suggestion.published? })

    def self.future_spaces
      none
    end

    def self.past_spaces
      closed
    end

    def self.log_presenter_class_for(_log)
      Decidim::Suggestions::AdminLog::SuggestionPresenter
    end

    # PUBLIC
    #
    # Returns true when an suggestion has been created by an individual person.
    # False in case it has been created by an authorized organization.
    #
    # RETURN boolean
    def created_by_individual?
      decidim_user_group_id.nil?
    end

    # PUBLIC
    #
    # RETURN boolean TRUE when the suggestion is open, false in case its
    # not closed.
    def open?
      !closed?
    end

    # PUBLIC
    #
    # Returns when an suggestion is closed. An suggestion is closed when
    # at least one of the following conditions is true:
    #
    # * It has been discarded.
    # * It has been rejected.
    # * It has been accepted.
    # * Signature collection period has finished.
    #
    # RETURNS BOOLEAN
    def closed?
      discarded? || rejected? || accepted? || !votes_enabled? || classified?
    end

    # PUBLIC
    #
    # Returns the author name. If it has been created by an organization it will
    # return the organization's name. Otherwise it will return author's name.
    #
    # RETURN string
    def author_name
      user_group&.name || author.name
    end

    # PUBLIC author_avatar_url
    #
    # Returns the author's avatar URL. In case it is not defined the method
    # falls back to decidim/default-avatar.svg
    #
    # RETURNS STRING
    def author_avatar_url
      author.avatar&.url ||
        ActionController::Base.helpers.asset_path("decidim/default-avatar.svg")
    end

    # PUBLIC banner image
    #
    # Overrides participatory space's banner image with the banner image defined
    # for the suggestion type.
    #
    # RETURNS string
    delegate :banner_image, to: :type

    delegate :document_number_authorization_handler, to: :type
    delegate :supports_required, to: :scoped_type

    def votes_enabled?
      votes_enabled_state? &&
        signature_start_date.present? && signature_start_date <= Date.current &&
        signature_end_date.present? && signature_end_date >= Date.current
    end

    def votes_enabled_state?
      published? || examinated? || debatted?
    end

    def votes_enabled_for_user?(user)
      votes_enabled? ||
        # (user && (created? || validating?)) # && has_authorship?(user))
        # Unregistered users should see unpublished suggestion in order to support/vote them via shared link
        (created? || validating?)
    end

    def unvotes_enabled_for_user?(user)
      votes_enabled_for_user?(user) && type.undo_online_signatures_enabled?
    end

    # Public: Check if the user has voted the question.
    #
    # Returns Boolean.
    def voted_by?(user)
      votes.where(author: user).any?
    end

    # Public: Checks if the organization has given an answer for the suggestion.
    #
    # Returns Boolean.
    def answered?
      answered_at.present?
    end

    # Public: Overrides scopes enabled flag available in other models like
    # participatory space or assemblies. For suggestions it won't be directly
    # managed by the user and it will be enabled by default.
    def scopes_enabled?
      true
    end

    # Public: Overrides scopes enabled attribute value.
    # For suggestions it won't be directly
    # managed by the user and it will be enabled by default.
    def scopes_enabled
      true
    end

    # Public: Publishes this suggestion
    #
    # Returns true if the record was properly saved, false otherwise.
    def publish!
      return false if published?

      update(
        published_at: Time.current,
        state: "published",
        signature_start_date: Date.current,
        signature_end_date: signature_end_date || Date.current + Decidim::Suggestions.default_signature_time_period_length
      )
    end

    #
    # Public: Unpublishes this suggestion
    #
    # Returns true if the record was properly saved, false otherwise.
    def unpublish!
      return false unless published?

      update(published_at: nil, state: "discarded")
    end

    # Public: Returns wether the signature interval is already defined or not.
    def has_signature_interval_defined?
      signature_end_date.present? && signature_start_date.present?
    end

    # Public: Returns the hashtag for the suggestion.
    def hashtag
      attributes["hashtag"].to_s.delete("#")
    end

    def supports_count
      face_to_face_votes = offline_votes.nil? || online_signature_type? ? 0 : offline_votes
      digital_votes = offline_signature_type? ? 0 : (suggestion_votes_count + suggestion_supports_count)
      digital_votes + face_to_face_votes
    end

    # Public: Returns the percentage of required supports reached
    def percentage
      return 100 if supports_goal_reached?

      supports_count * 100 / supports_required
    end

    # Public: Whether the supports required objective has been reached
    def supports_goal_reached?
      supports_count >= supports_required
    end

    # Public: Overrides slug attribute from participatory processes.
    def slug
      slug_from_id(id)
    end

    def to_param
      slug
    end

    # Public: Overrides the `comments_have_alignment?`
    # Commentable concern method.
    def comments_have_alignment?
      true
    end

    # Public: Overrides the `comments_have_votes?` Commentable concern method.
    def comments_have_votes?
      true
    end

    # PUBLIC
    #
    # Checks if user is the author or is part of the promotal committee
    # of the suggestion.
    #
    # RETURNS boolean
    def has_authorship?(user)
      return true if author.id == user.id

      committee_members.approved.where(decidim_users_id: user.id).any?
    end

    def author_users
      [author].concat(committee_members.excluding_author.map(&:user))
    end

    def accepts_offline_votes?
      published? && (offline_signature_type? || any_signature_type?)
    end

    def accepts_online_votes?
      votes_enabled? && (online_signature_type? || any_signature_type?)
    end

    def accepts_online_unvotes?
      accepts_online_votes? && type.undo_online_signatures_enabled?
    end

    def minimum_committee_members
      type.minimum_committee_members || Decidim::Suggestions.minimum_committee_members
    end

    def enough_committee_members?
      committee_members.approved.count >= minimum_committee_members
    end

    # PUBLIC
    #
    # Checks if the type the suggestion belongs to enables SMS code
    # verification step. Tis configuration is ignored if the organization
    # doesn't have the sms authorization available
    #
    # RETURNS boolean
    def validate_sms_code_on_votes?
      organization.available_authorizations.include?("sms") && type.validate_sms_code_on_votes?
    end

    # Public: Returns an empty object. This method should be implemented by
    # `ParticipatorySpaceResourceable`, but for some reason this model does not
    # implement this interface.
    def user_role_config_for(_user, _role_name)
      Decidim::ParticipatorySpaceRoleConfig::Base.new(:empty_role_name)
    end

    private

    def signature_type_allowed
      return if published?

      errors.add(:signature_type, :invalid) if type.allowed_signature_types_for_suggestions.exclude?(signature_type)
    end

    def notify_state_change
      return unless saved_change_to_state?

      notifier = Decidim::Suggestions::StatusChangeNotifier.new(suggestion: self)
      notifier.notify
    end

    def notify_creation
      notifier = Decidim::Suggestions::StatusChangeNotifier.new(suggestion: self)
      notifier.notify
    end

    # Allow ransacker to search for a key in a hstore column (`title`.`en`)
    [:title, :description].each do |column|
      ransacker column do |parent|
        Arel::Nodes::InfixOperation.new("->>", parent.table[column], Arel::Nodes.build_quoted(I18n.locale.to_s))
      end
    end

    # Allow ransacker to search on an Enum Field
    ransacker :state, formatter: proc { |int| states[int] }

    ransacker :type_id do
      Arel.sql("decidim_suggestions_type_scopes.decidim_suggestions_types_id")
    end

    # method for sort_link by number of supports
    ransacker :supports_count do
      query = <<~SQL
        (
          SELECT
            CASE
              WHEN signature_type = 0 THEN 0
              ELSE COALESCE(offline_votes, 0)
            END
            +
            CASE
              WHEN signature_type = 1 THEN 0
              ELSE suggestion_votes_count + suggestion_supports_count
            END
           FROM decidim_suggestions as suggestions
          WHERE suggestions.id = decidim_suggestions.id
          GROUP BY suggestions.id
        )
      SQL
      Arel.sql(query)
    end

    ransacker :id_string do
      Arel.sql(%{cast("decidim_suggestions"."id" as text)})
    end

    ransacker :author_name do
      Arel.sql("decidim_users.name")
    end

    ransacker :author_nickname do
      Arel.sql("decidim_users.nickname")
    end
  end
end
