import IdentifiedCollections
import XCTest

final class IdentifiedCollectionTests: XCTestCase {

  func testDefault() {
    let normal = MockContainer<Array<User>>(collection: [])
    XCTAssertFalse(normal.get())
  }

  func testConstrained() {
    let constrained = MockContainer<IdentifiedArrayOf<User>>(collection: [])
    XCTAssertTrue(constrained.get())
  }
}

private struct MockContainer<T: Collection> {
  let collection: T
}

extension MockContainer {
  func get() -> Bool {
    return false
  }
}

extension MockContainer where T: IdentifiedCollection {
  func get() -> Bool {
    return true
  }
}
