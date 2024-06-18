import OrderedCollections

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
  ///   - elements: A sequence of elements to use for the new array. Every element in `elements`
  ///     must have a unique id.
  ///   - id: The key path to an element's identifier.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  @_disfavoredOverload
  public init(
    uncheckedUniqueElements elements: some Sequence<Element>,
    id: KeyPath<Element, ID>
  ) {
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
  ///   - elements: A sequence of elements to use for the new array. Every element in `elements`
  ///     must have a unique id.
  ///   - id: The key path to an element's identifier.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  public init<S: Sequence<Element>>(
    uniqueElements elements: S,
    id: KeyPath<Element, ID>
  ) {
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

  /// Creates a new array from the elements in the given sequence, using a combining closure to
  /// determine the element for any elements with duplicate identity.
  ///
  /// You use this initializer to create an array when you have an arbitrary sequence of elements
  /// that may not have unique ids. This initializer calls the `combine` closure with the current
  /// and new elements for any duplicate ids. Pass a closure as `combine` that returns the element
  /// to use in the resulting array: The closure can choose between the two elements, combine them
  /// to produce a new element, or even throw an error.
  ///
  /// - Parameters:
  ///   - elements: A sequence of elements to use for the new array.
  ///   - id: The key path to an element's identifier.
  ///   - combine: Closure used to combine elements with duplicate ids.
  /// - Returns: A new array initialized with the unique elements of `elements`.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  public init(
    _ elements: some Sequence<Element>,
    id: KeyPath<Element, ID>,
    uniquingIDsWith combine: (Element, Element) throws -> Element
  ) rethrows {
    try self.init(
      id: id,
      _id: { $0[keyPath: id] },
      _dictionary: .init(
        elements.lazy.map { ($0[keyPath: id], $0) },
        uniquingKeysWith: combine
      )
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
  /// - Parameter elements: A sequence of elements to use for the new array. Every element in
  ///   `elements` must have a unique id.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  @_disfavoredOverload
  public init(uncheckedUniqueElements elements: some Sequence<Element>) {
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
  /// - Parameter elements: A sequence of elements to use for the new array. Every element in
  ///   `elements` must have a unique id.
  /// - Returns: A new array initialized with the elements of `elements`.
  /// - Precondition: The sequence must not have duplicate ids.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  public init<S: Sequence<Element>>(uniqueElements elements: S) {
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

  /// Creates a new array from the elements in the given sequence, using a combining closure to
  /// determine the element for any elements with duplicate ids.
  ///
  /// You use this initializer to create an array when you have an arbitrary sequence of elements
  /// that may not have unique ids. This initializer calls the `combine` closure with the current
  /// and new elements for any duplicate ids. Pass a closure as `combine` that returns the element
  /// to use in the resulting array: The closure can choose between the two elements, combine them
  /// to produce a new element, or even throw an error.
  ///
  /// - Parameters:
  ///   - elements: A sequence of elements to use for the new array.
  ///   - combine: Closure used to combine duplicated elements.
  /// - Returns: A new array initialized with the unique elements of `elements`.
  /// - Complexity: Expected O(*n*) on average, where *n* is the count of elements, if `ID`
  ///   implements high-quality hashing.
  @inlinable
  public init(
    _ elements: some Sequence<Element>,
    uniquingIDsWith combine: (Element, Element) throws -> Element
  ) rethrows {
    try self.init(
      id: \.id,
      _id: { $0.id },
      _dictionary: .init(
        elements.lazy.map { ($0.id, $0) },
        uniquingKeysWith: combine
      )
    )
  }
}

// MARK: - Deprecations

extension IdentifiedArray {
  @available(*, deprecated, renamed: "init(uniqueElements:id:)")
  public init(_ elements: some Sequence<Element>, id: KeyPath<Element, ID>) {
    self.init(uniqueElements: elements, id: id)
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray where Element: Identifiable, ID == Element.ID {
  @available(*, deprecated, renamed: "init(uniqueElements:)")
  public init(_ elements: some Sequence<Element>) {
    self.init(uniqueElements: elements)
  }
}
