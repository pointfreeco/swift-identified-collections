public protocol IdentifiedCollection<ID, Element>: Collection {
  associatedtype ID: Hashable

  associatedtype IDs: Collection<ID>

  var ids: IDs { get }

  subscript(id id: ID) -> Element? { get }
}

public protocol MutableIdentifiedCollection<ID, Element>: IdentifiedCollection {
  subscript(id id: ID) -> Element? { get set }
}
