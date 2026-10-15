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

  describe "#should_display?" do
    it "returns false when plugin is disabled" do
      SiteSetting.top_rank_by_reactions_enabled = false
      expect(described_class.new(topic).should_display?).to eq(false)
    end

    it "returns false when topic is a private message" do
      topic.update_columns(archetype: Archetype.private_message)
      expect(described_class.new(topic).should_display?).to eq(false)
    end

    it "returns false when topic has fewer posts than min_posts setting" do
      SiteSetting.top_rank_by_reactions_min_posts = 10
      expect(described_class.new(topic).should_display?).to eq(false)
    end

    it "returns true when requirements are met" do
      expect(described_class.new(topic).should_display?).to eq(true)
    end
  end

  describe "#top_posts" do
    it "returns empty array when should_display? is false" do
      SiteSetting.top_rank_by_reactions_enabled = false
      expect(described_class.new(topic).top_posts).to eq([])
    end

    it "excludes post 1 (OP) even if it has reactions" do
      10.times do
        u = Fabricate(:user)
        PostActionCreator.like(u, post1)
      end

      3.times do
        u = Fabricate(:user)
        PostActionCreator.like(u, post2)
      end

      results = described_class.new(topic).top_posts
      expect(results.map { |r| r[:id] }).not_to include(post1.id)
      expect(results.first[:id]).to eq(post2.id)
    end

    it "filters out posts below min_reactions threshold" do
      u1 = Fabricate(:user)
      PostActionCreator.like(u1, post2)

      3.times do
        u = Fabricate(:user)
        PostActionCreator.like(u, post3)
      end

      results = described_class.new(topic).top_posts
      expect(results.length).to eq(1)
      expect(results.first[:id]).to eq(post3.id)
      expect(results.first[:reaction_count]).to eq(3)
    end

    it "ranks posts descending by reaction count" do
      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      6.times { PostActionCreator.like(Fabricate(:user), post3) }
      2.times { PostActionCreator.like(Fabricate(:user), post4) }

      results = described_class.new(topic).top_posts
      expect(results.map { |r| r[:id] }).to eq([post3.id, post2.id, post4.id])
      expect(results[0][:rank]).to eq(1)
      expect(results[1][:rank]).to eq(2)
      expect(results[2][:rank]).to eq(3)
    end

    it "limits returned posts to max_posts setting" do
      SiteSetting.top_rank_by_reactions_max_posts = 1

      4.times { PostActionCreator.like(Fabricate(:user), post2) }
      3.times { PostActionCreator.like(Fabricate(:user), post3) }

      results = described_class.new(topic).top_posts
      expect(results.length).to eq(1)
      expect(results.first[:id]).to eq(post2.id)
    end
  end
end
