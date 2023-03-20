require 'spec_helper'
describe 'Sideload Limiting' do
  before do
    clear_model_memory_caches
  end

  context 'multi relationships' do
    before do
      stub_node_class('Person') do
        property :name
        property :active

        has_many :in, :posts, type: :posts\
      end

      stub_node_class('Post') do
        property :name

        has_one :out, :owner, origin: :posts, model_class: 'Person'
      end
    end

    context 'limit posts on person' do
      let(:person) { Person.create(name: 'P1', active: 'true') }
      
      before do
        1001.times { |n| Post.create(name: "Post-#{n}", owner: person) }
      end

      context 'no sideload limit and pagination true' do
        it 'apply default limit on sideload' do
          expect(Person.all.with_ordered_associations('posts', {},
            {max_page_size: 1_000, paginate: true})[0].posts.to_a.count).to eq(1_000)
        end
      end

      context 'sideload limit and pagination true' do
        it 'apply given sideload limit on sideload' do
          expect(Person.all.with_ordered_associations('10*posts', {},
            {max_page_size: 1_000, paginate: true})[0].posts.to_a.count).to eq(10)
        end
      end

      context 'sideload limit and pagination false' do
        it 'apply given sideload limit on sideload' do
          expect(Person.all.with_ordered_associations('10*posts', {},
            {max_page_size: 1_000, paginate: false})[0].posts.to_a.count).to eq(10)
        end
      end

      context 'no sideload limit and pagination false' do
        it 'apply given sideload limit on sideload' do
          expect(Person.all.with_ordered_associations('posts', {},
            {max_page_size: 1_000, paginate: false})[0].posts.to_a.count).to eq(1_001)
        end
      end
    end
  end
end
