require 'test_helper'

describe "HappyMapper with Comparable" do
  let(:left) { TParent.parse(sample_a) }
  let(:right) { TParent.parse(sample_b) }

  it "sez two identical documents should be equal" do
    assert_equal left, TParent.parse(sample_a)
  end

  it "sez two different documents should not be equal" do
    refute_equal left, right
  end

  describe HappyMapper::Differ do
    let(:result) { HappyMapper::Differ.new(left, right).diff }

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
      assert ! result.children[0].changed?
      assert ! result.children[1].changed?
      assert result.children[2].changed?
      assert_equal({"name" => "Vlad", "children" => [right.children[2]]}, result.changes)
      assert_equal({}, result.children[1].changes)
      assert_equal({"name" => "Alex"}, result.children[2].changes)
    end

    it "finds changes to  nested data" do
      result = HappyMapper::Differ.new(
        TParent.parse(nested_a),
        TParent.parse(nested_b),
      ).diff

      assert result.changed?
      assert result.children[0].changed?
      assert result.children[0].address.changed?
      assert result.children[0].address.street.changed?

      assert_equal({"children" => [result.children[0].compared]}, result.changes)
      assert_equal({"street" => "789 Maple St"}, result.children[0].address.changes)
      assert_equal("789 Maple St", result.children[0].address.street.compared)
    end

    it "find changes when the value is nil" do
      result = HappyMapper::Differ.new(
        TParent.parse("<parent/>"),
        TParent.parse("<parent name='Alex'/>"),
      ).diff

      assert result.changed?
      assert result.name.changed?
      assert_equal 'Alex', result.name.compared
    end

    it "finds changes when the left side element count is less than the right" do
      result = HappyMapper::Differ.new(
        TParent.parse(sample_a),
        TParent.parse(sample_a_plus),
      ).diff

      assert result.changed?
      assert result.children[3].changed?
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
      <street>567 Olice St</street>
      <city>Brooklyn</city>
    </address>
  </child>
</parent>
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
      <street>567 Olice St</street>
      <city>Brooklyn</city>
    </address>
  </child>
</parent>
    XML
  end
end
