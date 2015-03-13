require 'test_helper'

describe HappyMapper::ChangeLister do
  it "should find now changes between two equal objects" do
    a = TParent.parse(sample_a)
    b = TParent.parse(sample_a)

    d = HappyMapper::ChangeLister.new(a,b).find_changes

    assert_equal({}, d)
  end

  it "should find the changes between two simple objects" do
    a = TParent.parse(sample_a)
    b = TParent.parse(sample_b)

    d = HappyMapper::ChangeLister.new(a,b).find_changes
    
    assert_equal ["name", "children"], d.keys
    assert_equal "Vlad", d["name"]
    assert_equal [b.children[2]], d["children"]
  end

  it "should find changes in nested objects" do
    a = TParent.parse(sample_a)
    b = TParent.parse(sample_a)

    b.children.first.address = TAddress.new
    b.children.first.address.street = "123 Maple"

    d = HappyMapper::ChangeLister.new(a,b).find_changes

    assert_equal [b.children.first], d["children"]
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

  def sample_b
    <<-XML
<parent name="Vlad">
  <child name="Joe"/>
  <child name="Jane"/>
  <child name="Alex"/>
</parent>
    XML
  end
end
