import OrderedCollections

extension IdentifiedArray: _IdentifiedCollection {
  /// A read-only collection view for the ids contained in this array, as an `OrderedSet`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var ids: OrderedSet<ID> { self._dictionary.keys }
}

extension IdentifiedArray: _MutableIdentifiedCollection {
  /// Accesses the value associated with the given id for reading and writing.
  ///
  /// This *id-based* subscript returns the element identified by the given id if found in the
  /// array, or `nil` if no element is found.
  ///
  /// When you assign an element for an id and that element already exists, the array overwrites the
  /// existing value in place. If the array doesn't contain the element, it is appended to the
  /// array.
  ///
  /// If you assign `nil` for a given id, the array removes the element identified by that id.
  ///
  /// - Parameter id: The id to find in the array.
  /// - Returns: The element associated with `id` if found in the array; otherwise, `nil`.
  /// - Complexity: Looking up values in the array through this subscript has an expected complexity
  ///   of O(1) hashing/comparison operations on average, if `ID` implements high-quality hashing.
  ///   Updating the array also has an amortized expected complexity of O(1) -- although individual
  ///   updates may need to copy or resize the array's underlying storage.
  /// - Postcondition: Element identity must remain constant over modification. Modifying an
  ///   element's id will cause a crash.
  @inlinable
  @inline(__always)
  public subscript(id id: ID) -> Element? {
    _read { yield self._dictionary[id] }
    _modify {
      yield &self._dictionary[id]
      precondition(
        self._dictionary[id].map { self._id($0) == id } ?? true,
        "Element identity must remain constant"
      )
    }
  }
}
