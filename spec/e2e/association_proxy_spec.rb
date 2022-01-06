require 'spec_helper'
describe 'Association Proxy' do
  before do
    clear_model_memory_caches
  end

  context 'multi relationships' do
    before do
      stub_node_class('Person') do
        property :name

        has_many :out, :knows, model_class: 'Person', type: nil
        has_many :in, :posts, type: :posts
        has_many :in, :comments, type: :comments
        has_one :out, :parent, type: :parent, model_class: 'Person', dependent: :delete
        has_many :in, :children, origin: :parent, model_class: 'Person'
        has_many :out, :owner_comments, type: :comments, model_class: 'Comment'
      end

      stub_node_class('Post') do
        property :name

        has_one :out, :owner, origin: :posts, model_class: 'Person'
        has_many :in, :comments, type: :posts
      end

      stub_node_class('Comment') do
        property :text

        has_one :out, :owner, origin: :comments, model_class: 'Person'
        has_one :in, :comment_owner, origin: :owner_comments, model_class: 'Person'
        has_one :out, :post, origin: :comments, model_class: 'Post'
      end
    end

    def deep_traversal(person)
      person.knows.each(&method(:deep_traversal))
    end

    context 'variable lenght relationship with with_associations' do
      let(:node) { Person.create(name: 'Billy', knows: friend1) }
      let(:friend1) { Person.create(name: 'f-1', knows: friend2) }
      let(:friend2) { Person.create(name: 'f-2', knows: friend3) }
      let(:friend3) { Person.create(name: 'f-3') }
      let(:billy_comment) { Comment.create(text: 'billy-comment', owner: node) }
      let(:comment) { Comment.create(text: 'f-1-comment', owner: friend1) }

      before { Post.create(name: 'Post-1', owner: node, comments: [comment, billy_comment]) }

      it 'Raises error if attempting to eager load more than one zero length paths' do
        expect { Person.all.with_associations(['knows*0..','comments.owner.knows*0..']) }.to raise_error(RuntimeError, /Can not eager load more than one zero length path./)
      end

      it 'Should allow for string parameter with variable length relationship notation' do
        expect_queries(1) do
          Post.comments.with_associations(owner: 'knows*').map(&:owner).each(&method(:deep_traversal))
        end
      end

      it 'Should allow for zero length paths' do
        expect_queries(1) do
          Post.comments.with_associations(owner: 'knows*0..', ).map(&:owner).each(&method(:deep_traversal))
        end
      end

      it 'allows on demand retrieval beyond eagerly fetched associations' do
        expect(Post.owner.with_associations('knows*2')[0].knows[0].knows[0].knows[0].name).to eq 'f-3'
      end

      it 'Should allow for string parameter with fixed length relationship notation' do
        expect(queries_count do
          owners = Post.comments.with_associations('owner.knows*2').map(&:owner)
          owners.each(&method(:deep_traversal))
        end).to be > 1
      end

      it '* does not supress other relationships at the same level' do
        expect_queries(2) do
          expect(Post.owner(chainable: true).with_associations('knows*.comments').first.comments).to_not be_empty
        end
      end

      it 'Should allow for string parameter with variable length relationship notation' do
        expect_queries(1) do
          Post.owner(chainable: true).with_associations('knows*.comments').each do |owner|
            owner.knows.each do |known|
              known.knows[0].comments.to_a
            end
          end
        end
      end
    end
  end
end
