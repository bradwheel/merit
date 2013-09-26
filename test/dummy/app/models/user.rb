class User < ActiveRecord::Base
  has_merit

  has_many :comments

  unless defined?(ActionController::StrongParameters)
    attr_accessible :name
  end

  def show_badges
    badges_uniq = Badge.find_by_id(badge_ids)
    badges_uniq.collect{|b| "#{b.name.capitalize}#{badge_status(b)}" }.join(', ')
  end

  def badge_status(badge)
    status = []
    count = badges.select{|b| b.name == badge.name }.count
    status << "x#{count}" if count > 1
    status.present? ? " (#{status.join(', ')})" : ''
  end
end
