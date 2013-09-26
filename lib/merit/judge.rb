require_relative 'observer'

module Merit
  class Judge

    include Observer

    def initialize(sashes, rule, options = {})
      @sashes = sashes
      @rule = rule
      # FIXME: Too much context?
      # A Judge should apply reputation independently of the action
      @action = options[:action]
    end

    # Grant badge if rule applies. If it doesn't, and the badge is temporary,
    # then remove it.
    def apply_badges
      if rule_applies?
        grant_badges
      else
        remove_badges if @rule.temporary
      end
    end

    private

    def grant_badges
      @sashes.each do |sash|
        next unless new_or_multiple?(sash)
        badge_sash = sash.add_badge badge.id
        notify_observers(@action.id, badge_sash, 'granted')
      end
    end

    def remove_badges
      @sashes.each do |sash|
        badge_sash = sash.rm_badge badge.id
        notify_observers(@action.id, badge_sash, 'removed')
      end
    end

    def new_or_multiple?(sash)
      !sash.badge_ids.include?(badge.id) || @rule.multiple
    end

    def rule_applies?
      rule_object = BaseTargetFinder.find(@rule, @action)
      @rule.applies? rule_object
    end

    def badge
      @rule.badge
    end
  end
end
