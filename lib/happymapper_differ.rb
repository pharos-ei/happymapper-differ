require 'happymapper'

module HappyMapper
  require 'happymapper/differ'

  # equality based on the underlying XML
  def ==(other)
    ov = other.respond_to?(:to_xml) ? other.to_xml : other
    self.to_xml == ov
  end
end

