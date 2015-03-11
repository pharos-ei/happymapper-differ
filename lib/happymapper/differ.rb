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
      attribute_changes
      element_changes
      @changes
    end

    def attribute_changes
      @current.class.attributes.map(&:name).each do |attr|
        other_value = @compared.send(attr)
        if @current.send(attr) != other_value
          @changes[attr] = other_value
        end
      end
    end

    def element_changes
      @current.class.elements.map(&:name).each do |name|
        other_els = @compared.send(name)
        this_els  = @current.send(name)

        if this_els.is_a?(Array)
          this_els.each_with_index do |el, i|
            if el != other_els[i]
              @changes[name] ||= []
              @changes[name] << other_els[i]
            end
          end
        else
          if this_els != other_els
            @changes[name] = other_els
          end
        end
      end
    end
  end
end
