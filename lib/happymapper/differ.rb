require 'delegate'

module HappyMapper
  # Differ compares the differences betwee two HappyMapper objects.
  class Differ
    VERSION = 0.1

    def initialize(left, right)
      @left = left
      @right = right
    end

    # Diff is a method to find what elements and attributes have changed and
    # how.It extends each element and attribute with the DiffedItem module
    def diff
      out = setup(@left, @right)

      # setup for each element (has_one and has_many) and attribute
      all_items.map(&:name).compact.each do |name|
        value = out.send(name)
        rvalue = @right ? @right.send(name) : @right

        if value.is_a?(Array)
          # Find the side with the most items. If the right has more, the left
          # will be padded with UnExtendable instances
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

    protected

    # returns all the elements and attributes for the left class
    def all_items
      @left.class.attributes + @left.class.elements
    end

    def setup(item, compared)
      DiffedItem.create(item, compared)
    end

    def setup_element(item, compared)
      if item.is_a?(HappyMapper)
        Differ.new(item, compared).diff
      else
        setup(item, compared)
      end
    end
  end

  # nil, Float, and other classes can't be extended
  # so this object acts as wrapper
  class UnExtendable < SimpleDelegator
    def class
      __getobj__.class
    end
  end

  # DiffedItem is an extension which allows tracking changes between two
  # HappyMapper objects.
  module DiffedItem
    # The object this item is being compared to
    attr_accessor :compared
    alias_method :was, :compared

    def self.create(item, compared)
      begin
        item.extend(DiffedItem)
      rescue
        # this item is a Float, Nil or other class that can not be extended
        item = UnExtendable.new(item)
        item.extend(DiffedItem)
      end

      item.compared = compared
      item
    end

    def changed?
      if self.is_a?(HappyMapper)
        ! changes.empty?
      else
        self != compared
      end
    end

    def changes
      @changes ||= ChangeLister.new(self, compared).find_changes
    end
  end

  # ChangeLister creates a hash of all changes between the two objects
  class ChangeLister
    def initialize(current, compared)
      @current = current
      @compared = compared
      @changes = {}
    end

    def find_changes
      elements_and_attributes.map(&:name).each do |name|
        el  = @current.send(name)

        if el.is_a?(Array)
          many_changes(el, key: name)
        else
          other_el = get_compared_value(name)
          if el != other_el
            @changes[name] = other_el
          end
        end
      end

      @changes
    end

    # Handle change for has_many elements
    def many_changes(els, key:)
      other_els = get_compared_value(key) || []

      els.each_with_index do |el, i|
        if el != other_els[i]
          @changes[key] ||= []
          @changes[key] << other_els[i]
        end
      end
    end

    def get_compared_value(key)
      if @compared.respond_to?(key)
        @compared.send(key)
      else
        nil
      end
    end

    def elements_and_attributes
      @current.class.attributes + @current.class.elements
    end
  end
end
