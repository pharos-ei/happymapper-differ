# HappyMapper::Differ

In the unlikely scenario you use [HappyMapper](
https://github.com/dam5s/happymapper ) and you need to find differences between
two documents, this could be a solution.

Ok, your probably won't use or need this. But since I enjoy writing to myself here is how to use it.

__Note: this library is wildly memory inefficient__

````ruby
def left
  %Q{
  <person name="James">
    <item><name>Car</name></item>
    <item><name>Box</name></item>
  </person>
  }
end

def right
  %Q{
  <person name="Carl">
    <item><name>Car</name></item>
    <item><name>Red Box</name></item>
    <item><name>Cup</name></item>
  </person>
  }
end

require 'happymapper_differ'

class Person
  include HappyMapper

  tag 'person'
  attribute :name, String
  has_many :items, "Item"
end

class Item
  include HappyMapper
  has_one :name, String
end

result = HappyMapper::Differ.new(Person.parse(left), Person.parse(right)).diff

result.changed?
#=> true

result.changes
#=> {"name"=>"Carl", "items"=>[#<Item:0x007ffd2d8d5a68 @name="Red Box">, #<Item:0x007ffd2d8d5630 @name="Cup">]}

result.name.changed?
#=> true

result.name.was
#=> "Carl"

result.items[0].changed?
#=> false
result.items[1].changes?
#=> {"name"=>"Red Box"}
result.items[2].changed?
#=> true
result.items[2]
#=> nil
result.items[2].was
#=> #<Item:0x007fde2c045ee0 @name="Cup">
````

### Extended methods

HappyMapper::Differ extends each HappyMapper instance and element with the following methods:

|method|purpose|
|------|-------|
|changed?| returns true if this element, or a child has changed |
|changes | returns a has with each element or attribute which changed, and changed value |
|was | returns the prior(value from the right). If there is no change this will be the current value. |


## Contributing

1. Fork it ( https://github.com/pharos-ie/happymapper-differ/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
