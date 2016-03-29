require 'rails_helper'

RSpec.describe Site, type: :model do
  describe "validate" do
    shared_examples_for 'presence value' do
      context do
        let(:value) { 'some text' }
        it { expect { subject }.not_to raise_error }
      end
      context do
        let(:value) { nil }
        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
      end
      context do
        let(:value) { '' }
        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
      end
      context do
        let(:value) { ' ' }
        it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end
    describe "#name" do
      subject { described_class.create!(name: value, feed_url: 'valid_value') }
      it_behaves_like 'presence value'
    end
    describe "#feed_url" do
      subject { described_class.create!(name: 'valid_value', feed_url: value) }
      it_behaves_like 'presence value'
    end
  end
  describe "methods" do
  end
end
