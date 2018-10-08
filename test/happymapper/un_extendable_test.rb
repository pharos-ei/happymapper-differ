require 'test_helper'

describe HappyMapper::UnExtendable do
  let(:t) do
    HappyMapper::UnExtendable
      .new(type)
      .extend(HappyMapper::DiffedItem)
  end

  describe TrueClass do
    let(:type) { true }

    it { ! t.nil? }
    it "is comparable to a TrueClass" do
      assert_equal t, true
    end
  end

  describe Float do
    let(:type) { 1.1 }
    it { ! t.nil? }
    it "is comparable to a Float" do
      assert_equal 1.1, t
    end
  end

  describe NilClass do
    let(:type) { nil }
    it { t.nil? }
    it "is comparable to a Float" do
      assert_nil t
    end
  end
end
