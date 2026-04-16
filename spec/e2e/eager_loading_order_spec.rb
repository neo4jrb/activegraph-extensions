# frozen_string_literal: true

require 'spec_helper'

describe 'Eager Loading with Ordering' do
  before do
    clear_model_memory_caches
  end

  before do
    stub_node_class('Person') do
      property :name

      has_many :in, :posts, type: :posts
      has_one :out, :role, type: :role
      has_many :out, :knows, model_class: 'Person', type: nil
    end

    stub_node_class('Post') do
      property :name

      has_one :out, :owner, origin: :posts, model_class: 'Person'
      has_many :in, :comments, type: :comments
    end

    stub_node_class('Comment') do
      property :text

      has_one :out, :post, origin: :comments, model_class: 'Post'
    end

    stub_node_class('Role') do
      property :name
    end
  end

  describe 'sorted_association_paths order logic' do
    def sorted_path_names(query)
      query.send(:sorted_association_paths).map { |path| path.map(&:name).join('.') }
    end

    it 'returns correct order for two sideloads and one sort param' do
      query = Person.all.with_ordered_associations(%w[knows posts], { 'posts' => ['name'] })
      expect(sorted_path_names(query)).to eq(%w[posts knows])
    end

    it 'returns correct order for two sideloads and no sort params' do
      query = Person.all.with_ordered_associations('posts.comments', {})
      expect(sorted_path_names(query)).to eq(['posts', 'posts.comments'])
    end

    it 'returns correct order for two sideloads and two sort params' do
      query = Person.all.with_ordered_associations('posts.comments',
                                                   { 'posts' => ['name'], 'posts.comments' => ['text'] })
      expect(sorted_path_names(query)).to eq(['posts', 'posts.comments'])
    end

    it 'returns correct order for three sideloads, two sort params' do
      query = Person.all.with_ordered_associations(['knows', 'posts.comments'],
                                                   { 'posts' => ['name'], 'posts.comments' => ['text'] })
      expect(sorted_path_names(query)).to eq(['posts', 'posts.comments', 'knows'])
    end
  end

  describe 'sideloads with ordering' do
    let!(:alice) { Person.create(name: 'Alice') }
    let!(:bob) { Person.create(name: 'Bob') }
    let!(:charlie) { Person.create(name: 'Charlie') }

    let!(:post_alice) { Post.create(name: 'Zebra', owner: alice) }
    let!(:post_bob) { Post.create(name: 'Apple', owner: bob) }
    let!(:post_charlie) { Post.create(name: 'Mango', owner: charlie) }

    context 'single sideload' do
      let!(:post_alice2) { Post.create(name: 'Yacht', owner: alice) }
      it 'loads associations in a single query' do
        expect_queries(1) do
          Person.all.with_ordered_associations('posts', { 'posts' => ['name'] }).map(&:posts)
        end
      end

      it 'returns all person records with their posts loaded' do
        results = Person.all.with_ordered_associations('posts', { 'posts' => ['name'] }).to_a
        expect(results.map(&:name)).to eq(%w[Bob Charlie Alice])

        alice_result = results.find { |p| p.name == 'Alice' }
        expect(alice_result.posts.map(&:name)).to eq(%w[Yacht Zebra])
      end
    end

    context 'multiple sideloads' do
      let!(:comment_alice) { Comment.create(text: 'Comment on First', post: post_alice) }
      let!(:comment_bob) { Comment.create(text: 'Comment on Second', post: post_bob) }

      it 'loads nested associations in a single query' do
        expect_queries(1) do
          Person.all.with_ordered_associations('posts.comments', { 'posts' => ['name'] }).each do |person|
            person.posts.each { |post| post.comments.to_a }
          end
        end
      end

      it 'returns correct nested data' do
        results = Person.all.with_ordered_associations('posts.comments', { 'posts' => ['name'] }).to_a

        alice_result = results.find { |p| p.name == 'Alice' }
        expect(alice_result.posts.to_a.first.comments.map(&:text)).to include('Comment on First')

        bob_result = results.find { |p| p.name == 'Bob' }
        expect(bob_result.posts.to_a.first.comments.map(&:text)).to include('Comment on Second')
      end
    end
  end

  describe 'correct sideloads ordering with skip and limit' do
    let!(:alice) { Person.create(name: 'Alice') }
    let!(:bob) { Person.create(name: 'Bob') }
    let!(:charlie) { Person.create(name: 'Charlie') }

    # Post names control the ORDER BY on collection:
    # Bob's first post (Apple) < Charlie's first post (Mango) < Alice's first post (Zebra)
    let!(:post_alice) { Post.create(name: 'Zebra', owner: alice) }
    let!(:post_bob) { Post.create(name: 'Apple', owner: bob) }
    let!(:post_charlie) { Post.create(name: 'Mango', owner: charlie) }

    it 'orders main results by sideloaded association property' do
      results = Person.all
                      .with_ordered_associations('posts', { 'posts' => ['name'] })

      expect(results.map(&:name)).to eq(%w[Bob Charlie Alice])
    end

    it 'applies limit after sideload ordering' do
      results = Person.all
                      .with_ordered_associations('posts', { 'posts' => ['name'] })
                      .limit(2)

      expect(results.map(&:name)).to eq(%w[Bob Charlie])
    end

    it 'applies skip and limit after sideload ordering' do
      results = Person.all
                      .with_ordered_associations('posts', { 'posts' => ['name'] })
                      .skip(1).limit(1)

      expect(results.map(&:name)).to eq(%w[Charlie])
    end
  end

  describe 'multiple sideloads with order' do
    let!(:role_admin) { Role.create(name: 'Admin') }
    let!(:role_user) { Role.create(name: 'User') }
    let!(:role_guest) { Role.create(name: 'Guest') }

    let!(:alice) { Person.create(name: 'Alice', role: role_admin) }
    let!(:bob) { Person.create(name: 'Bob', role: role_user) }
    let!(:charlie) { Person.create(name: 'Charlie', role: role_guest) }

    let!(:post_b) { Post.create(name: 'Apple', owner: bob) }

    context 'when three sideloads with two orders' do
      let!(:post_a) { Post.create(name: 'Apple', owner: alice) }
      let!(:post_c) { Post.create(name: 'Banana', owner: charlie) }

      it 'returns correctly ordered data' do
        alice.knows << charlie
        bob.knows << alice

        results = Person.all
                        .with_ordered_associations(%w[posts role knows], {
                                                     'posts' => ['name'],
                                                     'knows' => ['name']
                                                   }).to_a

        # Should be ordered by posts.name: Alice (Apple), Bob (Apple), Charlie (Banana)
        # For Alice and Bob (same post name), order by knows.name: Bob (knows Alice), Alice (knows Charlie)
        expect(results.map(&:name)).to eq(%w[Bob Alice Charlie])

        bob_result = results[0]
        alice_result = results[1]
        charlie_result = results[2]

        expect(bob_result.posts.map(&:name)).to eq(['Apple'])
        expect(bob_result.knows.map(&:name)).to eq(['Alice'])
        expect(bob_result.role.name).to eq('User')

        expect(alice_result.posts.map(&:name)).to eq(['Apple'])
        expect(alice_result.knows.map(&:name)).to eq(['Charlie'])
        expect(alice_result.role.name).to eq('Admin')

        expect(charlie_result.posts.map(&:name)).to eq(['Banana'])
        expect(charlie_result.knows).to be_empty
        expect(charlie_result.role.name).to eq('Guest')
      end
    end

    context 'when two sideloads with one order and limit clause' do
      let!(:post_a) { Post.create(name: 'Zebra', owner: alice) }

      it 'returns correctly ordered data' do
        expect_queries(1) do
          results = Person.all
                          .with_ordered_associations(%w[posts role], { 'posts' => ['name'] })
                          .limit(1)
                          .to_a

          expect(results.length).to eq(1)
          first_res = results.first
          expect(first_res.name).to eq('Bob')
          expect(first_res.posts.map(&:name)).to eq(['Apple'])
          expect(first_res.role.name).to eq('User')
        end
      end
    end
  end

  describe 'without order spec' do
    let!(:alice) { Person.create(name: 'Alice') }
    let!(:post) { Post.create(name: 'Post-1', owner: alice) }

    it 'loads associations without reordering paths' do
      expect_queries(1) do
        Person.all.with_ordered_associations('posts', {}).each do |person|
          person.posts.to_a
        end
      end
    end

    it 'returns all data correctly' do
      results = Person.all.with_ordered_associations('posts', {}).to_a
      expect(results.first.posts.map(&:name)).to eq(['Post-1'])
    end

    it 'does not interfere with skip/limit' do
      Person.create(name: 'Bob')
      results = Person.all.with_ordered_associations('posts', {}).limit(1).to_a
      expect(results.length).to eq(1)
    end
  end

  describe 'descending order on sideloaded association' do
    let!(:alice) { Person.create(name: 'Alice') }
    let!(:bob) { Person.create(name: 'Bob') }
    let!(:charlie) { Person.create(name: 'Charlie') }

    let!(:post_alice) { Post.create(name: 'Zebra', owner: alice) }
    let!(:post_bob) { Post.create(name: 'Apple', owner: bob) }
    let!(:post_charlie) { Post.create(name: 'Mango', owner: charlie) }

    it 'orders main results by sideloaded property descending' do
      results = Person.all
                      .with_ordered_associations('posts', { 'posts' => ['name DESC'] })
                      .to_a

      # DESC post name order: Alice (Zebra), Charlie (Mango), Bob (Apple)
      expect(results.map(&:name)).to eq(%w[Alice Charlie Bob])
    end

    it 'applies skip/limit with descending order' do
      results = Person.all
                      .with_ordered_associations('posts', { 'posts' => ['name DESC'] })
                      .limit(2)
                      .to_a

      # DESC post name order, limit 2: Alice (Zebra), Charlie (Mango)
      expect(results.map(&:name)).to eq(%w[Alice Charlie])
    end
  end

  describe 'variable length relationship with ordering' do
    let!(:alice) { Person.create(name: 'Alice') }
    let!(:friend1) { Person.create(name: 'Friend-1', knows: friend2) }
    let!(:friend2) { Person.create(name: 'Friend-2') }
    let!(:post_yak) { Post.create(name: 'Yak', owner: alice) }

    before { alice.knows << friend1 }

    it 'loads variable length associations with ordering in a single query' do
      expect_queries(1) do
        results = Person.all
                        .with_ordered_associations(['knows*', 'posts'], { 'posts' => ['name'] })
                        .to_a

        alice_result = results.find { |p| p.name == 'Alice' }
        expect(alice_result.posts.to_a).not_to be_empty
        expect(alice_result.knows.to_a).not_to be_empty
      end
    end

    context 'ordering Person records by their first post name' do
      let!(:bob) { Person.create(name: 'Bob') }
      let!(:post_zebra) { Post.create(name: 'Zebra', owner: alice) }
      let!(:post_apple) { Post.create(name: 'Apple', owner: bob) }

      it 'orders Person records even with rel_length present' do
        results = Person.all
                        .with_ordered_associations(['knows*', 'posts'], { 'posts' => ['name'] })
                        .limit(2)
                        .to_a

        expect(results.map(&:name)).to eq(%w[Bob Alice])
      end
    end
  end
end
