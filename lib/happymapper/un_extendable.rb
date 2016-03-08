module HappyMapper
  # nil, Float, and other classes can't be extended
  # so this object acts as wrapper
  class UnExtendable < SimpleDelegator
    def class
      __getobj__.class
    end

    def nil?
      __getobj__.nil?
    end
  end
end
