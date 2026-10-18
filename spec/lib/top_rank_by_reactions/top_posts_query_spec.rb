# frozen_string_literal: true

require "rails_helper"

RSpec.describe TopRankByReactions::TopPostsQuery do
  fab!(:user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic) }
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

  describe "#should_display?" do
    it "returns false when plugin is disabled" do
      SiteSetting.top_rank_by_reactions_enabled = false
      expect(query.should_display?).to eq(false)
    end

    it "returns false for a private message topic" do
      topic.update_columns(archetype: Archetype.private_message)
      expect(query.should_display?).to eq(false)
    end

    it "returns false when the topic has fewer posts than min_posts" do
      SiteSetting.top_rank_by_reactions_min_posts = 10
      expect(query.should_display?).to eq(false)
    end
  end

  describe "#top_post_ids" do
    it "excludes the OP (post_number = 1) from bumped results" do
      10.times { PostActionCreator.like(Fabricate(:user), post1) }
      3.times  { PostActionCreator.like(Fabricate(:user), post2) }

      ids = query.top_post_ids
      expect(ids).not_to include(post1.id)
      expect(ids).to include(post2.id)
    end

    it "filters posts below min_reactions" do
      1.times { PostActionCreator.like(Fabricate(:user), post2) }  # below min of 2
      3.times { PostActionCreator.like(Fabricate(:user), post3) }  # above min of 2

      ids = query.top_post_ids
      expect(ids).to eq([post3.id])
    end

    it "ranks posts descending by reaction count" do
      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      6.times { PostActionCreator.like(Fabricate(:user), post3) }
      2.times { PostActionCreator.like(Fabricate(:user), post4) }

      ids = query.top_post_ids
      expect(ids).to eq([post3.id, post2.id, post4.id])
    end

    it "honours max_posts setting" do
      SiteSetting.top_rank_by_reactions_max_posts = 1
      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      3.times { PostActionCreator.like(Fabricate(:user), post3) }

      ids = query.top_post_ids
      expect(ids.length).to eq(1)
      expect(ids.first).to eq(post2.id)
    end
  end

  describe "#top_posts_data" do
    it "returns structured post details including rank, reaction_count, and author" do
      5.times { PostActionCreator.like(Fabricate(:user), post3) }
      3.times { PostActionCreator.like(Fabricate(:user), post2) }

      data = query.top_posts_data
      expect(data.length).to eq(2)
      expect(data.first[:id]).to eq(post3.id)
      expect(data.first[:rank]).to eq(1)
      expect(data.first[:reaction_count]).to eq(5)
      expect(data.first[:user][:username]).to eq(user.username)
      expect(data.second[:id]).to eq(post2.id)
      expect(data.second[:rank]).to eq(2)
      expect(data.second[:reaction_count]).to eq(3)
    end
  end

  describe "TopRankByReactions.order_sql_for_topic" do
    it "constructs a valid CASE order SQL string" do
      3.times { PostActionCreator.like(Fabricate(:user), post3) }
      2.times { PostActionCreator.like(Fabricate(:user), post2) }

      sql = TopRankByReactions.order_sql_for_topic(topic)
      expect(sql).to include("CASE posts.post_number WHEN 1 THEN 0")
      expect(sql).to include("WHEN #{post3.id} THEN 1")
      expect(sql).to include("WHEN #{post2.id} THEN 2")
    end
  end
end
