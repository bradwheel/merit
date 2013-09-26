require 'test_helper'

class NavigationTest < ActiveSupport::IntegrationCase
  test 'user sign up should grant badge to itself' do
    visit '/users/new'
    fill_in 'Name', with: 'Jack'
    assert_difference('Merit::ActivityLog.count') do
      click_button('Create User')
    end

    user = User.where(name: 'Jack').first
    assert_equal [Merit::Badge.by_name('just-registered').first], user.badges
  end

  test 'User#add_badge should add one badge, #rm_badge should delete one' do
    user = User.create(name: 'test-user')
    assert_equal [], user.badges

    badge = Merit::Badge.first
    user.add_badge badge.id
    user.add_badge badge.id
    assert_equal [badge, badge], user.badges
    assert_equal [user], badge.users

    user.rm_badge badge.id
    assert_equal [badge], user.reload.badges
  end

  test 'Remove inexistent badge should do nothing' do
    user = User.create(name: 'test-user')
    assert_equal [], user.badges
    user.rm_badge 1
    assert_equal [], user.badges
  end

  test 'users#index should grant badge multiple times' do
    user = User.create(name: 'test-user')

    # Multiple rule
    assert_difference 'badges_by_name(user, "gossip").count', 3 do
      3.times { visit '/users' }
    end

    # Namespaced controller
    assert_no_difference 'badges_by_name(user, "visited_admin").count' do
      visit '/users'
    end
    assert_difference 'badges_by_name(user, "visited_admin").count' do
      visit '/admin/users'
    end

    # Wildcard controllers
    assert_difference 'badges_by_name(user, "wildcard_badge").count', 3 do
      visit '/admin/users'
      visit '/api/users'
      visit '/users'
    end
  end

  test 'user workflow should grant some badges at some times' do
    # Commented 9 times, no badges yet
    user = User.create(name: 'test-user')
    # Create needed friend user object
    friend = User.create(name: 'friend')

    (1..9).each do |i|
      Comment.create(
        name: "Title #{i}",
        comment: "Comment #{i}",
        user_id: user.id,
        votes: 8
      )
    end
    assert user.badges.empty?, 'Should not have badges'

    # Make tenth comment, assert 10-commenter badge granted
    visit '/comments/new'
    fill_in 'Name', with: 'Hi!'
    fill_in 'Comment', with: 'Hi bro!'
    fill_in 'User', with: user.id
    assert_difference('Merit::ActivityLog.count', 2) do
      click_button('Create Comment')
    end

    assert_equal [Merit::Badge.by_name('has_commenter_friend').first], friend.reload.badges

    # Vote (to 5) a user's comment, assert relevant-commenter badge granted
    relevant_comment = user.comments.where(votes: 8).first
    visit '/comments'
    within("tr#c_#{relevant_comment.id}") do
      click_link '2'
    end

    relevant_badge = Merit::Badge.by_name('relevant-commenter').first
    user_badges    = User.where(name: 'test-user').first.badges
    assert user_badges.include?(relevant_badge), "User badges: #{user.badges.collect(&:name).inspect} should contain relevant-commenter badge."

    # Edit user's name by long name
    # tests ruby code in grant_on is being executed, and gives badge
    user = User.where(name: 'test-user').first
    user_badges = user.badges

    visit "/users/#{user.id}/edit"
    fill_in 'Name', with: 'long_name!'
    click_button('Update User')

    user = User.where(name: 'long_name!').first
    autobiographer_badge = Merit::Badge.by_name('autobiographer').first
    assert user.badges.include?(autobiographer_badge), "User badges: #{user.badges.collect(&:name).inspect} should contain autobiographer badge."

    # Edit user's name by short name
    # tests ruby code in grant_on is being executed, and removes badge
    visit "/users/#{user.id}/edit"
    fill_in 'Name', with: 'abc'
    assert_difference('Merit::ActivityLog.count', 2) do
      click_button('Update User')
    end
    # Last one is point granting, previous one is badge removing
    assert_equal 'removed', Merit::ActivityLog.all[-2].description

    user = User.where(name: 'abc').first
    assert !user.badges.include?(autobiographer_badge), "User badges: #{user.badges.collect(&:name).inspect} should remove autobiographer badge."
  end

  def badges_by_name(user, name)
    user.reload.badges.select{|b| b.name == name }
  end
end
