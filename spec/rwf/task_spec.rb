# frozen_string_literal: true

RSpec.describe RWF::Task, type: :model do
  describe '::call' do
    it { expect(RWF::Task.(->(*) { true }, {}).success?).to be true }
  end
end
