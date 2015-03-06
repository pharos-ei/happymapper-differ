module HappyMapper
  class Differ 
    VERSION = 0.1

    def initialize(left, right)
      @left = left
      @right = right
    end

    def changed?
      @left.to_xml == @right.to_xml
    end

    # Diff is a memory ineffecient and ugly method to find what elements and
    # attributes have changed and how.
    #
    # It extends each element and attribute with the DiffedItem module
    # and makes a clone of the original element for comparison.
    def diff
      out = @left
      setup(@left, @right)

      all = out.class.attributes + out.class.elements

      # setup for each element (has_one and has_many) and attribute
      all.map(&:name).compact.each do |name|
        value = out.send(name)
        if value.nil?
          value = NilLike.new 
          out.send("#{name}=", value)
        end

        if value.is_a?(Array)
          # Find the side with the most items
          # If the right has more, the left will be padded with NilLike instances
          count = [value.size, (@right.send(name) || []).size].max

          count.times do |i|
            value[i] = NilLike.new if value[i].nil?
            setup_element(value[i], @right.send(name)[i])
          end
        else
          setup_element(value, @right.send(name))
        end
      end

      out
    end

    def handle_nil(name)
      out.send("#{name}=", NilLike.new)
    end

    def setup(item, compared)
      n = item.clone
      item.extend(DiffedItem)
      item.compared = compared 
      item.original = n
    end

    def setup_element(item, compared)
      if(item.is_a?(HappyMapper))
        Differ.new(item, compared).diff
      else
        setup(item, compared)
      end
    end

    # nil can't be cloned or extended
    # so this object behaves like nil
    class NilLike
      def nil?
        true
      end

      def to_s
        "nil"
      end

      def inspect
        nil.inspect
      end
    end
  end

  module DiffedItem
    attr_accessor :original

    # The object this item is being compared to
    attr_accessor :compared
    alias :was :compared

    def changed?
      original != compared
    end

    def changes
      cs = {} # the changes

      original.class.attributes.map(&:name).each do |attr|
        other_value = compared.send(attr)
        if original.send(attr) != other_value
          cs[attr] = other_value
        end
      end

      original.class.elements.map(&:name).each do |name|
        other_els = compared.send(name)
        this_els  = original.send(name)

        if this_els.is_a?(Array)
          this_els.each_with_index do |el, i|
            if el != other_els[i]
              cs[name] ||= []
              cs[name] << other_els[i]
            end
          end
        else
          if this_els != other_els
            cs[name] = other_els
          end
        end
      end

      cs
    end

    def ==(other)
      original == other
    end
  end
end
