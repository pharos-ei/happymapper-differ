require 'delegate'

module HappyMapper
  class Differ 
    VERSION = 0.1

    def initialize(left, right)
      @left = left
      @right = right
    end

    def changed?
      @left != @right
    end

    # Diff is a memory ineffecient and ugly method to find what elements and
    # attributes have changed and how.
    #
    # It extends each element and attribute with the DiffedItem module
    def diff
      out = setup(@left, @right)

      all = out.class.attributes + out.class.elements

      # setup for each element (has_one and has_many) and attribute
      all.map(&:name).compact.each do |name|
        value = out.send(name)
        rvalue = @right ? @right.send(name) : @right

        if value.is_a?(Array)
          # Find the side with the most items
          # If the right has more, the left will be padded with UnExtendable instances
          count = [value.size, (rvalue || []).size].max

          count.times do |i|
            value[i] = setup_element(value[i], (rvalue || [])[i])
          end
        else
          value = setup_element(value, rvalue)
        end

        out.send("#{name}=", value)
      end

      out
    end

    def setup(item, compared)
      # how to avoid cloning?
      # a wrapper with method missing?
      begin
        item.extend(DiffedItem)
      rescue
        item = UnExtendable.new(item)
        item.extend(DiffedItem)
      end

      item.compared = compared 
      item
    end

    def setup_element(item, compared)
      if(item.is_a?(HappyMapper))
        Differ.new(item, compared).diff
      else
        setup(item, compared)
      end
    end

    # nil, Float, and other classes can't be extended
    # so this object acts as wrapper
    class UnExtendable < SimpleDelegator
      def class
        __getobj__.class
      end
    end
  end

  module DiffedItem
    # The object this item is being compared to
    attr_accessor :compared
    alias :was :compared

    def changed?
      self != compared
    end

    def changes
      cs = {} # the changes

      self.class.attributes.map(&:name).each do |attr|
        other_value = compared.send(attr)
        if self.send(attr) != other_value
          cs[attr] = other_value
        end
      end

      self.class.elements.map(&:name).each do |name|
        other_els = compared.send(name)
        this_els  = self.send(name)

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
  end
end
