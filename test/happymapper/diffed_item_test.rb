require 'test_helper'

class DIPerson
  include HappyMapper
  tag 'person'

  attribute 'name', String
  has_one :child, DIPerson
end

describe HappyMapper::DiffedItem do
  describe "HappyMapper objects" do
    let(:a) { TAddress.parse("<address><street>Maple</street></address>") }
    let(:b) { TAddress.parse("<address><street>Main</street></address>") }

    describe "changed" do
      it "is true when the values are not equal" do
        di = HappyMapper::DiffedItem.create(a,b)
        assert_equal true, di.changed?
      end

      it "is false when the objects are the same" do
        di = HappyMapper::DiffedItem.create(a,a)
        assert_equal false, di.changed?
      end
    end
  end

  describe "non HappyMapper Objects" do
    describe "changed" do
      it "is true when the values are note equal" do
        di = HappyMapper::DiffedItem.create("A","B")
        assert_equal true, di.changed?
        assert_equal "B", di.was

        di = HappyMapper::DiffedItem.create(1,2)
        assert_equal true, di.changed?
        assert_equal 2, di.was

        di = HappyMapper::DiffedItem.create(1,1)
        assert_equal false, di.changed?
        assert_equal 1, di.was
      end
    end
  end

  describe "with nil objects" do
    # BUG: When there are two nil objects, the second replaces the first.
    it "should keep the correct state" do
      debugger
      a = HappyMapper::DiffedItem.create(nil, 'A')
      b = HappyMapper::DiffedItem.create(nil, 'B')

      assert_equal 'A', a.was
      assert_equal 'B', b.was
    end
  end
end


