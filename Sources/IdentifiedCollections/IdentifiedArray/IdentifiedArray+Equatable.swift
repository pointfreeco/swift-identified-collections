extension IdentifiedArray: Equatable where Element: Equatable {
  @inlinable
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id && lhs.elementsEqual(rhs)
  }
}
