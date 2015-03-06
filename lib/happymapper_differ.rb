require 'happymapper'

module HappyMapper
  require 'happymapper/differ'

  # equality based on the underlying XML
  def ==(other)
    self.to_xml == other.to_xml
  end
end

