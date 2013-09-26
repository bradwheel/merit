module Merit
  # Sash is a container for reputation data for meritable models. It's an
  # indirection between meritable models and badges and scores (one to one
  # relationship).
  #
  # It's existence make join models like badges_users and scores_users
  # unnecessary. It should be transparent at the application.
  class Sash < ActiveRecord::Base
    has_many :badges_sashes, dependent: :destroy


    def badges
      badge_ids.map { |id| Badge.find id }
    end

    def badge_ids
      badges_sashes.map(&:badge_id)
    end

    def add_badge(badge_id)
      bs = BadgesSash.new(badge_id: badge_id)
      self.badges_sashes << bs
      bs
    end

    def rm_badge(badge_id)
      badges_sashes.find_by_badge_id(badge_id).try(:destroy)
    end

  end
end
