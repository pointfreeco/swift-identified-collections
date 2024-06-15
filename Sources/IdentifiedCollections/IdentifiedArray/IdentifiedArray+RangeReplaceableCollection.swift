import OrderedCollections

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray: RangeReplaceableCollection
where Element: Identifiable, ID == Element.ID {
  /// Creates an empty array.
  ///
  /// This initializer is equivalent to initializing with an empty array literal.
  ///
  /// - Complexity: O(1)
  @inlinable
  public init() {
    self.init(id: \.id, _id: { $0.id }, _dictionary: .init())
  }

  @inlinable
  public mutating func replaceSubrange(
    _ subrange: Range<Int>, with newElements: some Collection<Element>
  ) {
    self._dictionary.removeSubrange(subrange)
    self._dictionary.reserveCapacity(self.count + newElements.count)
    for element in newElements.reversed() {
      self._dictionary.updateValue(
        element,
        forKey: self._id(element),
        insertingAt: subrange.startIndex
      )
    }
  }
}

extension IdentifiedArray {
  /// Removes and returns the element at the specified position.
  ///
  /// All the elements following the specified position are moved to close the resulting gap.
  ///
  /// - Parameter index: The position of the element to remove.
  /// - Returns: The removed element.
  /// - Precondition: `index` must be a valid index of the collection that is not equal to the
  ///   collection's end index.
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    self._dictionary.remove(at: index).value
  }

  /// Removes all members from the set.
  ///
  /// - Parameter keepingCapacity: If `true`, the array's storage capacity is preserved; if `false`,
  ///   the underlying storage is released. The default is `false`.
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    self._dictionary.removeAll(keepingCapacity: keepCapacity)
  }

  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a collection that meets particular criteria. The
  /// order of the remaining elements is preserved.
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the collection as its argument
  ///   and returns a Boolean value indicating whether the element should be removed from the
  ///   collection.
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    try self._dictionary.removeAll(where: { try shouldBeRemoved($0.value) })
  }

  /// Removes the first element of a non-empty array.
  ///
  /// The members following the removed item need to be moved to close the resulting gap in the
  /// storage array.
  ///
  /// - Returns: The removed element.
  /// - Precondition: The array must be non-empty.
  /// - Complexity: O(`count`).
  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    self._dictionary.removeFirst().value
  }

  /// Removes the first `n` elements of the collection.
  ///
  /// The members following the removed items need to be moved to close the resulting gap in the
  /// storage array.
  ///
  /// - Parameter n: The number of elements to remove from the collection.
  /// - Precondition: `n` must be greater than or equal to zero and must not exceed the number of
  ///   elements in the collection.
  /// - Complexity: O(`count`).
  @inlinable
  public mutating func removeFirst(_ n: Int) {
    self._dictionary.removeFirst(n)
  }

  /// Removes the last element of a non-empty array.
  ///
  /// - Returns: The removed element.
  /// - Precondition: The array must be non-empty.
  /// - Complexity: Expected to be O(`1`) on average, if `ID` implements high-quality hashing.
  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    self._dictionary.removeLast().value
  }

  /// Removes the last `n` element of the set.
  ///
  /// - Parameter n: The number of elements to remove from the collection.
  /// - Precondition: `n` must be greater than or equal to zero and must not exceed the number of
  ///   elements in the collection.
  /// - Complexity: Expected to be O(`n`) on average, if `ID` implements high-quality hashing.
  @inlinable
  public mutating func removeLast(_ n: Int) {
    self._dictionary.removeLast(n)
  }

  /// Removes the specified subrange of elements from the collection.
  ///
  /// All the elements following the specified subrange are moved to close the resulting gap.
  ///
  /// - Parameter bounds: The subrange of the collection to remove.
  /// - Precondition: The bounds of the range must be valid indices of the collection.
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Int>) {
    self._dictionary.removeSubrange(bounds)
  }

  /// Removes the specified subrange of elements from the collection.
  ///
  /// All the elements following the specified subrange are moved to close the resulting gap.
  ///
  /// - Parameter bounds: The subrange of the collection to remove.
  /// - Precondition: The bounds of the range must be valid indices of the collection.
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func removeSubrange<R>(_ bounds: R)
  where R: RangeExpression, R.Bound == Int {
    self._dictionary.removeSubrange(bounds)
  }

  /// Reserves enough space to store the specified number of elements.
  ///
  /// This method ensures that the array has unique, mutable, contiguous storage, with space
  /// allocated for at least the requested number of elements.
  ///
  /// If you are adding a known number of elements to a dictionary, call this method once before
  /// the first insertion to avoid multiple reallocations.
  ///
  /// Do not call this method in a loop -- it does not use an exponential allocation strategy, so
  /// doing that can result in quadratic instead of linear performance.
  ///
  /// - Parameter minimumCapacity: The minimum number of elements that the array should be able to
  ///   store without reallocating its storage.
  /// - Complexity: O(`max(count, minimumCapacity)`)
  @inlinable
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    self._dictionary.reserveCapacity(minimumCapacity)
  }
}
