class Object
  def if_present
    present? ? self : nil
  end

  def noop(reason)
    # Use this method to 'programmatically document' that a method does
    # nothing. Then write a test for that method that asserts #noop
    # is called with that reason.
  end
end
