extension IdentifiedArray {
  /// Creates a new array from the elements in the given sequence, which must not contain duplicate
  /// ids.
  ///
  /// In optimized builds, this initializer does not verify that the ids are actually unique. This
  /// makes creating the array somewhat faster if you know for sure that the elements are unique
  /// (e.g., because they come from another collection with guaranteed-unique members. However, if
  /// you accidentally call this initializer with duplicate members, it can return a corrupt array
  /// value that may be difficult to debug.
  ///
  /// - Parameters:
  ///   - elements: A sequence of elements to use for the new array. Every key in `elements`
  ///     must be unique.
  ///   - id: The key path to an element's identifier.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  @_disfavoredOverload
  public init<S>(
    uncheckedUniqueElements elements: S,
    id: KeyPath<Element, ID>
  )
  where S: Sequence, S.Element == Element {
    self.init(
      id: id,
      _id: { $0[keyPath: id] },
      _dictionary: .init(uncheckedUniqueKeysWithValues: elements.lazy.map { ($0[keyPath: id], $0) })
    )
  }

  /// Creates a new array from the elements in the given sequence.
  ///
  /// You use this initializer to create an array when you have a sequence of elements with unique
  /// ids. Passing a sequence with duplicate ids to this initializer results in a runtime error.
  ///
  /// - Parameters:
  ///   - elements: A sequence of elements to use for the new array. Every key in
  ///     `keysAndValues` must be unique.
  ///   - id: The key path to an element's identifier.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  public init<S>(
    uniqueElements elements: S,
    id: KeyPath<Element, ID>
  )
  where S: Sequence, S.Element == Element {
    if S.self == Self.self {
      self = elements as! Self
      return
    }
    if S.self == SubSequence.self {
      self.init(uncheckedUniqueElements: elements, id: id)
      return
    }
    self.init(
      id: id,
      _id: { $0[keyPath: id] },
      _dictionary: .init(uniqueKeysWithValues: elements.lazy.map { ($0[keyPath: id], $0) })
    )
  }

  /// Creates a new array from an existing array. This is functionally the same as copying the value
  /// of `elements` into a new variable.
  ///
  /// - Parameter elements: The elements to use as members of the new set.
  /// - Complexity: O(1)
  @inlinable
  public init(_ elements: Self) {
    self = elements
  }

  /// Creates a new set from an existing slice of another dictionary.
  ///
  /// - Parameter elements: The elements to use as members of the new array.
  /// - Complexity: This operation is expected to perform O(`elements.count`) operations on average,
  ///   provided that `ID` implements high-quality hashing.
  @inlinable
  public init(_ elements: SubSequence) {
    self.init(uncheckedUniqueElements: elements, id: elements.base.id)
  }

  /// Creates an empty array.
  ///
  /// - Parameter id: The key path to an element's identifier.
  /// - Complexity: O(1)
  @inlinable
  public init(id: KeyPath<Element, ID>) {
    self.init(id: id, _id: { $0[keyPath: id] }, _dictionary: .init())
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray where Element: Identifiable, ID == Element.ID {
  /// Creates a new array from the elements in the given sequence, which must not contain duplicate
  /// ids.
  ///
  /// In optimized builds, this initializer does not verify that the ids are actually unique. This
  /// makes creating the array somewhat faster if you know for sure that the elements are unique
  /// (e.g., because they come from another collection with guaranteed-unique members. However, if
  /// you accidentally call this initializer with duplicate members, it can return a corrupt array
  /// value that may be difficult to debug.
  ///
  /// - Parameter elements: A sequence of elements to use for the new array. Every key in `elements`
  ///   must be unique.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  @_disfavoredOverload
  public init<S>(uncheckedUniqueElements elements: S) where S: Sequence, S.Element == Element {
    self.init(
      id: \.id,
      _id: { $0.id },
      _dictionary: .init(uncheckedUniqueKeysWithValues: elements.lazy.map { ($0.id, $0) })
    )
  }

  /// Creates a new array from the elements in the given sequence.
  ///
  /// You use this initializer to create an array when you have a sequence of elements with unique
  /// ids. Passing a sequence with duplicate ids to this initializer results in a runtime error.
  ///
  /// - Parameters elements: A sequence of elements to use for the new array. Every key in
  ///   `keysAndValues` must be unique.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  public init<S>(uniqueElements elements: S) where S: Sequence, S.Element == Element {
    if S.self == Self.self {
      self = elements as! Self
      return
    }
    if let elements = elements as? SubSequence {
      self.init(uncheckedUniqueElements: elements, id: elements.base.id)
      return
    }
    self.init(
      id: \.id,
      _id: { $0.id },
      _dictionary: .init(uniqueKeysWithValues: elements.lazy.map { ($0.id, $0) })
    )
  }
}

// MARK: - Deprecations

extension IdentifiedArray {
  @available(*, deprecated, renamed: "init(uniqueElements:id:)")
  public init<S>(_ elements: S, id: KeyPath<Element, ID>) where S: Sequence, S.Element == Element {
    self.init(uniqueElements: elements, id: id)
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray where Element: Identifiable, ID == Element.ID {
  @available(*, deprecated, renamed: "init(uniqueElements:)")
  public init<S>(_ elements: S) where S: Sequence, S.Element == Element {
    self.init(uniqueElements: elements)
  }
}
