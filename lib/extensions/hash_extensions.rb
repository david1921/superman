class Hash
  def assert_has_keys(required_keys, optional_keys = [])
    assert_valid_keys *(required_keys + optional_keys)
    missing_keys = required_keys.flatten - keys
    raise(ArgumentError, "Missing key(s): #{missing_keys.join(", ")}") unless missing_keys.empty?
  end
end
