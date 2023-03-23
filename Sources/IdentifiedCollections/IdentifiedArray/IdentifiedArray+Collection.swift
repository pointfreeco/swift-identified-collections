import OrderedCollections

extension IdentifiedArray: Collection {
  @inlinable
  @inline(__always)
  public var startIndex: Int { self._dictionary.keys.startIndex }

  @inlinable
  @inline(__always)
  public var endIndex: Int { self._dictionary.keys.endIndex }

  @inlinable
  @inline(__always)
  public func index(after i: Int) -> Int { self._dictionary.keys.index(after: i) }

  /// Returns a new array containing the elements of the array that satisfy the given predicate.
  ///
  /// - Parameter isIncluded: A closure that takes an element as its argument and returns a Boolean
  ///   value indicating whether it should be included in the returned array.
  /// - Returns: An array of the elements that `isIncluded` allows.
  /// - Complexity: O(`count`)
  @inlinable
  public func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    try .init(
      id: self.id,
      _id: self._id,
      _dictionary: self._dictionary.filter { try isIncluded($1) }
    )
  }
}
