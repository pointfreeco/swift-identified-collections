/// A collection of elements that can be uniquely identified.
public protocol _IdentifiedCollection<ID, Element>: Collection {
  /// A type that uniquely identifies elements in the collection.
  associatedtype ID: Hashable

  /// A type that describes all of the ids in the collection.
  associatedtype IDs: Collection<ID>

  /// A collection of ids associated with elements in the collection.
  ///
  /// This collection must contain elements equal to `map(\.id)`.
  var ids: IDs { get }

  /// Accesses the value associated with the given id for reading.
  subscript(id id: ID) -> Element? { get }
}

/// A mutable collection of elements that can be uniquely identified.
public protocol _MutableIdentifiedCollection<ID, Element>: _IdentifiedCollection, MutableCollection
{
  /// Accesses the value associated with the given id for reading.
  subscript(id id: ID) -> Element? { get set }
}
