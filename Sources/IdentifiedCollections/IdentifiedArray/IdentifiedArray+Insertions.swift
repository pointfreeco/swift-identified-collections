import OrderedCollections

extension IdentifiedArray {
  /// Append a new member to the end of the array, if the array doesn't already contain it.
  ///
  /// - Parameter item: The element to add to the array.
  /// - Returns: A pair `(inserted, index)`, where `inserted` is a Boolean value indicating whether
  ///   the operation added a new element, and `index` is the index of `item` in the resulting
  ///   array.
  /// - Complexity: The operation is expected to perform O(1) copy, hash, and compare operations on
  ///   the `ID` type, if it implements high-quality hashing.
  @inlinable
  @inline(__always)
  @discardableResult
  public mutating func append(_ item: Element) -> (inserted: Bool, index: Int) {
    self.insert(item, at: self.endIndex)
  }

  /// Append the contents of a sequence to the end of the set, excluding elements that are already
  /// members.
  ///
  /// - Parameter elements: A finite sequence of elements to append.
  /// - Complexity: The operation is expected to perform amortized O(1) copy, hash, and compare
  ///   operations on the `Element` type, if it implements high-quality hashing.
  @inlinable
  public mutating func append(contentsOf newElements: some Sequence<Element>) {
    self.reserveCapacity(self.count + newElements.underestimatedCount)
    for element in newElements {
      self.append(element)
    }
  }

  /// Insert a new member to this array at the specified index, if the array doesn't already contain
  /// it.
  ///
  /// - Parameter item: The element to insert.
  /// - Returns: A pair `(inserted, index)`, where `inserted` is a Boolean value indicating whether
  ///   the operation added a new element, and `index` is the index of `item` in the resulting
  ///   array. If `inserted` is true, then the returned `index` may be different from the index
  ///   requested.
  ///
  /// - Complexity: The operation is expected to perform amortized O(`self.count`) copy, hash, and
  ///   compare operations on the `ID` type, if it implements high-quality hashing. (Insertions need
  ///   to make room in the storage array to add the inserted element.)
  @inlinable
  @discardableResult
  public mutating func insert(_ item: Element, at i: Int) -> (inserted: Bool, index: Int) {
    if let existing = self._dictionary.index(forKey: _id(item)) {
      return (false, existing)
    }
    self._dictionary.updateValue(item, forKey: _id(item), insertingAt: i)
    return (true, i)
  }

  /// Replace the member at the given index with a new value of the same identity.
  ///
  /// - Parameter item: The new value that should replace the original element. `item` must match
  ///   the identity of the original value.
  /// - Parameter index: The index of the element to be replaced.
  /// - Returns: The original element that was replaced.
  /// - Complexity: Amortized O(1).
  @inlinable
  @discardableResult
  public mutating func update(_ item: Element, at i: Int) -> Element {
    let old = self._dictionary.elements[i].key
    precondition(
      _id(item) == old, "The replacement item must match the identity of the original"
    )
    return self._dictionary.updateValue(item, forKey: old)!
  }

  /// Adds the given element to the array unconditionally, either appending it to the array, or
  /// replacing an existing value if it's already present.
  ///
  /// - Parameter item: The value to append or replace.
  /// - Returns: The original element that was replaced by this operation, or `nil` if the value was
  ///   appended to the end of the collection.
  /// - Complexity: The operation is expected to perform amortized O(1) copy, hash, and compare
  ///   operations on the `ID` type, if it implements high-quality hashing.
  @inlinable
  @discardableResult
  public mutating func updateOrAppend(_ item: Element) -> Element? {
    self._dictionary.updateValue(item, forKey: _id(item))
  }

  /// Adds the given element into the set unconditionally, either inserting it at the specified
  /// index, or replacing an existing value if it's already present.
  ///
  /// - Parameter item: The value to append or replace.
  /// - Parameter index: The index at which to insert the new member if `item` isn't already in the
  ///   set.
  /// - Returns: The original element that was replaced by this operation, or `nil` if the value was
  ///   newly inserted into the collection.
  /// - Complexity: The operation is expected to perform amortized O(1) copy, hash, and compare
  ///   operations on the `ID` type, if it implements high-quality hashing.
  @inlinable
  @discardableResult
  public mutating func updateOrInsert(
    _ item: Element,
    at i: Int
  ) -> (originalMember: Element?, index: Int) {
    self._dictionary.updateValue(item, forKey: _id(item), insertingAt: i)
  }
}
