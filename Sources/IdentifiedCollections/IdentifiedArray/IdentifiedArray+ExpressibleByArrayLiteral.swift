extension IdentifiedArray: ExpressibleByArrayLiteral where Element: Identifiable, ID == Element.ID {
  @inlinable
  public init(arrayLiteral elements: Element...) {
    self.init(uniqueElements: elements)
  }
}
