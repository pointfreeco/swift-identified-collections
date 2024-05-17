import OrderedCollections

extension IdentifiedArray: MutableCollection {
  @inlinable
  @inline(__always)
  public subscript(position: Int) -> Element {
    _read { yield self._dictionary.elements.values[position] }
    set {
      let key = _id(newValue)
      if let index = self._dictionary.keys.firstIndex(of: key) {
        self._dictionary.swapAt(index, position)
        self._dictionary.updateValue(newValue, forKey: key)
      } else {
        self._dictionary.remove(at: position)
        self._dictionary.updateValue(newValue, forKey: key, insertingAt: position)
      }
    }
    _modify {
      yield &self._dictionary.elements.values[position]
      precondition(
        self._dictionary.elements.keys[position] == _id(self._dictionary.elements.values[position]),
        "Element identity must remain constant"
      )
    }
  }

  /// Reorders the elements of the array such that all the elements that match the given predicate
  /// are after all the elements that don't match.
  ///
  /// After partitioning a collection, there is a pivot index `p` where no element before `p`
  /// satisfies the `belongsInSecondPartition` predicate and every element at or after `p` satisfies
  /// `belongsInSecondPartition`.
  ///
  /// - Parameter belongsInSecondPartition: A predicate used to partition the collection. All
  ///   elements satisfying this predicate are ordered after all elements not satisfying it.
  /// - Returns: The index of the first element in the reordered collection that matches
  ///  `belongsInSecondPartition`. If no elements in the collection match
  ///  `belongsInSecondPartition`, the returned index is equal to the collection's `endIndex`.
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Int {
    try self._dictionary.partition { (_, value) in
      try belongsInSecondPartition(value)
    }
  }

  /// Reverses the elements of the array in place.
  ///
  /// - Complexity: O(`count`)
  @inlinable
  public mutating func reverse() {
    self._dictionary.reverse()
  }

  /// Shuffles the collection in place.
  ///
  /// Use the `shuffle()` method to randomly reorder the elements of an array.
  ///
  /// This method is equivalent to calling ``shuffle(using:)``, passing in the system's default
  /// random generator.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the collection.
  @inlinable
  public mutating func shuffle() {
    self._dictionary.shuffle()
  }

  /// Shuffles the collection in place, using the given generator as a source for randomness.
  ///
  /// You use this method to randomize the elements of a collection when you are using a custom
  /// random number generator.
  ///
  /// - Parameter generator: The random number generator to use when shuffling the collection.
  /// - Complexity: O(*n*), where *n* is the length of the collection.
  /// - Note: The algorithm used to shuffle a collection may change in a future version of Swift.
  ///   If you're passing a generator that results in the same shuffled order each time you run your
  ///   program, that sequence may change when your program is compiled using a different version of
  ///   Swift.
  @inlinable
  public mutating func shuffle<T: RandomNumberGenerator>(using generator: inout T) {
    self._dictionary.shuffle(using: &generator)
  }

  /// Sorts the collection in place, using the given predicate as the comparison between elements.
  ///
  /// When you want to sort a collection of elements that don't conform to the `Comparable`
  /// protocol, pass a closure to this method that returns `true` when the first element should be
  /// ordered before the second.
  ///
  /// Alternatively, use this method to sort a collection of elements that do conform to
  /// `Comparable` when you want the sort to be descending instead of ascending. Pass the
  /// greater-than operator (`>`) operator as the predicate.
  ///
  /// `areInIncreasingOrder` must be a *strict weak ordering* over the elements. That is, for any
  /// elements `a`, `b`, and `c`, the following conditions must hold:
  ///
  ///   * `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
  ///   * If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are both `true`, then
  ///     `areInIncreasingOrder(a, c)` is also `true`. (Transitive comparability)
  ///   * Two elements are *incomparable* if neither is ordered before the other according to the
  ///     predicate. If `a` and `b` are incomparable, and `b` and `c` are incomparable, then `a`
  ///     and `c` are also incomparable. (Transitive incomparability)
  ///
  /// The sorting algorithm is not guaranteed to be stable. A stable sort preserves the relative
  /// order of elements for which `areInIncreasingOrder` does not establish an order.
  ///
  /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its first argument should
  ///   be ordered before its second argument; otherwise, `false`. If `areInIncreasingOrder` throws
  ///   an error during the sort, the elements may be in a different order, but none will be lost.
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public mutating func sort(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows {
    try self._dictionary.sort(by: { try areInIncreasingOrder($0.value, $1.value) })
  }

  /// Exchanges the values at the specified indices of the array.
  ///
  /// Both parameters must be valid indices below ``endIndex``. Passing the same index as both `i`
  /// and `j` has no effect.
  ///
  /// - Parameters:
  ///   - i: The index of the first value to swap.
  ///   - j: The index of the second value to swap.
  /// - Complexity: O(1) when the array's storage isn't shared with another value; O(`count`)
  ///   otherwise.
  @inlinable
  public mutating func swapAt(_ i: Int, _ j: Int) {
    self._dictionary.swapAt(i, j)
  }
}

extension IdentifiedArray where Element: Comparable {
  /// Sorts the set in place.
  ///
  /// You can sort an ordered set of elements that conform to the `Comparable` protocol by calling
  /// this method. Elements are sorted in ascending order.
  ///
  /// To sort the elements of your collection in descending order, pass the greater-than operator
  /// (`>`) to the ``sort(by:)`` method.
  ///
  /// The sorting algorithm is not guaranteed to be stable. A stable sort preserves the relative
  /// order of elements that compare equal.
  ///
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public mutating func sort() {
    self.sort(by: <)
  }
}
