import OrderedCollections

public protocol IdentifiedCollection {
  associatedtype ID: Hashable
  associatedtype Element

  var id: KeyPath<Element, ID> { get }

  @inlinable
  @inline(__always)
  var ids: OrderedSet<ID> { get }

  @inlinable
  @inline(__always)
  var elements: [Element] { get }

  @inlinable
  @inline(__always)
  subscript(id id: ID) -> Element? { get set }

  @inlinable
  func contains(_ element: Element) -> Bool

  @inlinable
  @inline(__always)
  func index(id: ID) -> Int?

  @inlinable
  @discardableResult
  mutating func remove(_ element: Element) -> Element?

  @inlinable
  @discardableResult
  mutating func remove(id: ID) -> Element?
}
