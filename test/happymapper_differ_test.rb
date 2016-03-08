require 'test_helper'

describe "HappyMapper with Comparable" do
  let(:left) { TParent.parse(sample_a) }
  let(:right) { TParent.parse(sample_b) }

  describe HappyMapper::Differ do
    let(:result) { HappyMapper::Differ.new(left, right).diff }

    it "finds no changes for identical documents" do
      result = HappyMapper::Differ.new(
        left,
        TParent.parse(sample_a)
      ).diff

      assert ! result.changed?
      assert ! result.name.changed?
      assert_equal({}, result.changes)
    end

    it "finds attribute changes" do
      result = HappyMapper::Differ.new(
        TParent.parse("<parent name='Roz'/>"),
        TParent.parse("<parent name='Alex'/>"),
      ).diff

      assert result.changed?
      assert result.name.changed?
      assert_equal({"name" => "Alex"}, result.changes)
    end

    it "finds changes to has_one elements" do
      a = TAddress.parse(address_a)
      b = TAddress.parse(address_b)
      result = HappyMapper::Differ.new(a, b).diff

      assert_equal({"street" => "123 Park Ave"}, result.changes)
    end

    it "finds changes to has_many elements" do
      assert result.children.changed?
      assert ! result.children[0].changed?
      assert ! result.children[1].changed?
      assert result.children[2].changed?


      assert_equal({"name" => "Vlad", "children" => [right.children[2]]}, result.changes)
      assert_equal({}, result.children[1].changes)
      assert_equal({"name" => "Alex"}, result.children[2].changes)
    end

    it "finds changes to nested data" do
      result = HappyMapper::Differ.new(
        TParent.parse(nested_a),
        TParent.parse(nested_b),
      ).diff

      # why is the name being injected
      assert_equal result.children.last.address.to_xml, result.children.last.address.was.to_xml

      assert result.changed?
      assert result.children[0].changed?
      assert result.children[0].address.changed?
      assert result.children[0].address.street.changed?

      assert_equal({"children" => [result.children[0].compared]}, result.changes)
      assert_equal({"street" => "789 Maple St"}, result.children[0].address.changes)
      assert_equal("789 Maple St", result.children[0].address.street.compared)
    end

    it "find changes when the value is nil XX" do
      result = HappyMapper::Differ.new(
        TParent.parse("<parent/>"),
        TParent.parse("<parent name='Justin'/>"),
      ).diff

      assert result.changed?
      assert result.name.changed?
      assert_equal 'Justin', result.name.compared
    end

    it "finds changes when the left side element count is less than the right" do
      result = HappyMapper::Differ.new(
        TParent.parse(sample_a),
        TParent.parse(sample_a_plus),
      ).diff

      assert result.changed?
      assert result.children[3].changed?
      assert result.children[3].nil?
    end

    it "handles a variet of types" do
      result = HappyMapper::Differ.new(
        TTypes.parse(types_a),
        TTypes.parse(types_b)
      ).diff

      assert result.changed?
      assert_equal Float, result.float.class
      assert_equal 1.1, result.float
      assert_equal 11.1, result.float.was
    end

    it "gracefully handles mismatched objects" do
      result = HappyMapper::Differ.new(
        TParent.parse(sample_a),
        TParent.parse("<parent/>"),
      ).diff

      assert result.changed?
      assert result.changes
    end

    it "handles nil right side" do
      di = HappyMapper::Differ.new(left,nil).diff
      assert_equal true, di.changed?
      assert_equal ["name","children"], di.changes.keys

      p = TParent.parse("<parent><child/><child/></parent>")
      di = HappyMapper::Differ.new(p,nil).diff
      assert_equal true, di.changed?
      assert_equal ["children"], di.changes.keys
    end

    it "errors if the left is nil" do
      assert_raises NoMethodError do
        di = HappyMapper::Differ.new(nil,right).diff
        assert_equal false, di.changed?
      end
    end
  end

  def sample_a
    <<-XML
<parent name="Roz">
  <child name="Joe"/>
  <child name="Jane"/>
  <child name="Jason"/>
</parent>
    XML
  end

  def sample_a_plus
    <<-XML
<parent name="Roz">
  <child name="Joe"/>
  <child name="Jane"/>
  <child name="Jason"/>
  <child name="Baxter"/>
</parent>
    XML
  end

  def sample_b
    <<-XML
<parent name="Vlad">
  <child name="Joe"/>
  <child name="Jane"/>
  <child name="Alex"/>
</parent>
    XML
  end

  def address_a
    <<-XML
    <address>
      <name>Mr. Jones</name>
      <street>123 Maple St</street>
      <city>Brooklyn</city>
    </address>
    XML
  end

  def address_b
    <<-XML
    <address>
      <name>Mr. Jones</name>
      <street>123 Park Ave</street>
      <city>Brooklyn</city>
    </address>
    XML
  end

  def nested_a
    <<-XML
<parent name="Roz">
  <child name="Joe">
    <address>
      <street>123 Maple St</street>
      <city>Brooklyn</city>
    </address>
  </child>
  <child name="Jane">
    <address>
      <street>567 Olive St</street>
      <city>Brooklyn</city>
    </address>
  </child>
</parent>
    XML
  end

  def addy
    <<-XML
    <address>
      <street>567 Olive St</street>
      <city>Brooklyn</city>
    </address>
    XML
  end
  # Joe's address changed
  def nested_b
    <<-XML
<parent name="Roz">
  <child name="Joe">
    <address>
      <street>789 Maple St</street>
      <city>Brooklyn</city>
    </address>
  </child>
  <child name="Jane">
    <address>
      <street>567 Olive St</street>
      <city>Brooklyn</city>
    </address>
  </child>
</parent>
    XML
  end

  def types_a
    <<-XML
    <types
      float="1.1"
      int="2"
      bool="true"
    />
    XML
  end

  def types_b
    <<-XML
    <types
      float="11.1"
      int="12"
      bool="false"
    />
    XML
  end
end
