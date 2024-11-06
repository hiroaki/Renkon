require 'rails_helper'

RSpec.describe Channel, type: :model do
  describe '基本' do
    let!(:channel) { FactoryBot.build(:channel) }
    it '既定の Factory が valid であり、レコードが保存できる' do
      expect { channel.save! }.not_to raise_error
    end
  end

  describe 'バリデーション' do
    subject { described_class.new(params).valid? }

    context do
      let!(:params) { { title: "aaa", src: "http://example.com/rss" } }
      it { is_expected.to be true }
    end

    context do
      let!(:params) { { title: nil, src: "http://example.com/rss" } }
      it { is_expected.to be false }
    end

    context do
      let!(:params) { { title: "aaa", src: "" } }
      it { is_expected.to be false }
    end
  end

  describe '.all_with_count_items' do
    let!(:channel1) { FactoryBot.create(:channel) }
    let!(:channel2) { FactoryBot.create(:channel) }
    let!(:channel3) { FactoryBot.create(:channel) }

    before do
      FactoryBot.create(:item, title: 'ch1-1', channel: channel1, unread: true, disabled: false)
      FactoryBot.create(:item, title: 'ch1-2', channel: channel1, unread: true, disabled: true)
      FactoryBot.create(:item, title: 'ch1-3', channel: channel1, unread: false, disabled: false)
      FactoryBot.create(:item, title: 'ch1-4', channel: channel1, unread: false, disabled: true)

      FactoryBot.create(:item, title: 'ch3-1', channel: channel3, unread: true, disabled: false)
      FactoryBot.create(:item, title: 'ch3-2', channel: channel3, unread: true, disabled: true)
      FactoryBot.create(:item, title: 'ch3-3', channel: channel3, unread: true, disabled: false)
      FactoryBot.create(:item, title: 'ch3-4', channel: channel3, unread: true, disabled: true)
    end

    describe 'channels count' do
      context do
        it {
          rel = Channel.all_with_count_items
          expect(rel.to_a.size).to eq 3
        }
      end

      context do
        it {
          rel = Channel.all_with_count_items(unread: true)
          expect(rel.to_a.size).to eq 3
        }
      end

      context do
        it {
          rel = Channel.all_with_count_items(unread: false)
          expect(rel.to_a.size).to eq 3
        }
      end
    end

    describe 'count of items of channel#1' do
      context do
        let!(:unread) { true }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel1.id }.count_items(unread: unread)).to eq 1 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel1.id }.count_items(unread: unread)).to eq 2 }
      end
    end

    describe 'count of items of channel#2' do
      context do
        let!(:unread) { true }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel2.id }.count_items(unread: unread)).to eq 0 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel2.id }.count_items(unread: unread)).to eq 0 }
      end
    end

    describe 'count of items of channel#3' do
      context do
        let!(:unread) { true }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel3.id }.count_items(unread: unread)).to eq 2 }
      end
      context do
        let!(:unread) { false }
        let!(:rel) { Channel.all_with_count_items(unread: unread) }
        it { expect(rel.find { |r| r.id == channel3.id }.count_items(unread: unread)).to eq 2 }
      end
    end
  end
end
