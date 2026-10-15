# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopRankByReactions::TopPostsQuery do
  fab!(:user)
  fab!(:topic)
  fab!(:post1) { Fabricate(:post, topic: topic, post_number: 1, user: user) }
  fab!(:post2) { Fabricate(:post, topic: topic, post_number: 2, user: user) }
  fab!(:post3) { Fabricate(:post, topic: topic, post_number: 3, user: user) }
  fab!(:post4) { Fabricate(:post, topic: topic, post_number: 4, user: user) }
  fab!(:post5) { Fabricate(:post, topic: topic, post_number: 5, user: user) }

  before do
    SiteSetting.top_rank_by_reactions_enabled = true
    SiteSetting.top_rank_by_reactions_min_posts = 5
    SiteSetting.top_rank_by_reactions_min_reactions = 2
    SiteSetting.top_rank_by_reactions_max_posts = 3
    topic.update_columns(posts_count: 5)
  end

  subject(:query) { described_class.new(topic) }

  describe "#top_posts via should_display?" do
    it "returns [] when plugin is disabled" do
      SiteSetting.top_rank_by_reactions_enabled = false
      expect(query.top_posts).to eq([])
    end

    it "returns [] for a private message topic" do
      topic.update_columns(archetype: Archetype.private_message)
      expect(query.top_posts).to eq([])
    end

    it "returns [] when the topic has fewer posts than min_posts" do
      SiteSetting.top_rank_by_reactions_min_posts = 10
      expect(query.top_posts).to eq([])
    end
  end

  describe "#top_posts ranking" do
    it "excludes the OP (post_number = 1) from results" do
      10.times { PostActionCreator.like(Fabricate(:user), post1) }
      3.times  { PostActionCreator.like(Fabricate(:user), post2) }

      ids = query.top_posts.map { |r| r[:id] }
      expect(ids).not_to include(post1.id)
      expect(ids).to include(post2.id)
    end

    it "filters posts below min_reactions" do
      1.times { PostActionCreator.like(Fabricate(:user), post2) }  # below min of 2
      3.times { PostActionCreator.like(Fabricate(:user), post3) }  # above min

      results = query.top_posts
      expect(results.map { |r| r[:id] }).to eq([post3.id])
    end

    it "ranks posts descending by reaction count" do
      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      6.times { PostActionCreator.like(Fabricate(:user), post3) }
      2.times { PostActionCreator.like(Fabricate(:user), post4) }

      results = query.top_posts
      expect(results.map { |r| r[:id] }).to eq([post3.id, post2.id, post4.id])
      expect(results.map { |r| r[:rank] }).to eq([1, 2, 3])
    end

    it "honours max_posts setting" do
      SiteSetting.top_rank_by_reactions_max_posts = 1
      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      3.times { PostActionCreator.like(Fabricate(:user), post3) }

      results = query.top_posts
      expect(results.length).to eq(1)
      expect(results.first[:id]).to eq(post2.id)
    end

    it "includes user info in the result" do
      3.times { PostActionCreator.like(Fabricate(:user), post2) }
      results = query.top_posts
      expect(results.first[:user][:username]).to eq(user.username)
    end
  end
end
