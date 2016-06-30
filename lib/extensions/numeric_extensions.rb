class Numeric
  include Liquid::Droppable

  def is_fractional?
    self.to_i != self
  end
end
