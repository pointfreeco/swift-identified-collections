#if swift(>=5.5)
  extension IdentifiedArray: @unchecked Sendable
  where ID: Sendable, Element: Sendable {}
#endif
