# frozen_string_literal: true

RSpec.describe RWF::Result, type: :model do
  subject(:result) { RWF::Result.new(params) }

  let(:params) { {} }

  describe '#to_s' do
    it { expect(result.to_s).to eq 'Initial' }
    it { expect(result.success!.to_s).to eq 'Success' }
    it { expect(result.failure!.to_s).to eq 'Failure' }
  end
end
