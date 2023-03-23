import OrderedCollections

extension IdentifiedArray: Encodable where Element: Encodable {
  @inlinable
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(ContiguousArray(self._dictionary.values))
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension IdentifiedArray: Decodable
where Element: Decodable & Identifiable, ID == Element.ID {
  @inlinable
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    self.init()
    while !container.isAtEnd {
      let element = try container.decode(Element.self)
      let (inserted, _) = self.append(element)
      guard inserted else {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Duplicate element at offset \(container.currentIndex - 1)"
        )
        throw DecodingError.dataCorrupted(context)
      }
    }
  }
}
