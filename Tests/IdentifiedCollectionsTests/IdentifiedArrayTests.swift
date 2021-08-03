import XCTest

@testable import IdentifiedCollections

extension Int: Identifiable { public var id: Self { self } }

private struct User: Equatable, Identifiable {
  let id: Int
  var name: String
}

final class IdentifiedArrayTests: XCTestCase {
  func testIds() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.ids, [1, 2, 3])
  }

  func testElements() {
    let array: IdentifiedArray = [
      User(id: 1, name: "Blob"),
      User(id: 2, name: "Blob, Jr."),
      User(id: 3, name: "Blob, Sr."),
    ]

    XCTAssertEqual(array.elements, array.map { $0 })
  }

  func testSubscriptId() {
    var array: IdentifiedArray = [
      User(id: 1, name: "Blob"),
      User(id: 2, name: "Blob, Jr."),
      User(id: 3, name: "Blob, Sr."),
    ]
    XCTAssertEqual(array[id: 1], User(id: 1, name: "Blob"))
    XCTAssertEqual(array[id: 2], User(id: 2, name: "Blob, Jr."))
    XCTAssertEqual(array[id: 3], User(id: 3, name: "Blob, Sr."))
    array[id: 1]?.name += ", Esq."
    XCTAssertEqual(array[id: 1], User(id: 1, name: "Blob, Esq."))
    array[id: 2]?.name.removeLast(5)
    XCTAssertEqual(array[id: 2], User(id: 2, name: "Blob"))
    array[id: 3]?.name.removeLast(5)
    XCTAssertEqual(array[id: 3], User(id: 3, name: "Blob"))
    array[id: 3] = nil
    XCTAssertEqual(array[id: 3], nil)

    array[id: 4] = User(id: 4, name: "Blob, Sr.")
    XCTAssertEqual(
      array,
      [
        User(id: 1, name: "Blob, Esq."),
        User(id: 2, name: "Blob"),
        User(id: 4, name: "Blob, Sr."),
      ]
    )
  }

  func testContainsElement() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertTrue(array.contains(2))
  }

  func testIndexId() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.index(id: 2), 1)
  }

  func testRemoveElement() {
    var array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.remove(2), 2)
    XCTAssertEqual(array, [1, 3])
  }

  func testRemoveId() {
    var array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.remove(id: 2), 2)
    XCTAssertEqual(array, [1, 3])
  }

  func testCodable() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(
      try JSONDecoder().decode(IdentifiedArray.self, from: JSONEncoder().encode(array)),
      array
    )
    XCTAssertEqual(
      try JSONDecoder().decode(IdentifiedArray.self, from: Data("[1,2,3]".utf8)),
      array
    )
    XCTAssertThrowsError(
      try JSONDecoder().decode(IdentifiedArrayOf<Int>.self, from: Data("[1,1,1]".utf8))
    ) { error in
      guard case let DecodingError.dataCorrupted(ctx) = error
      else { return XCTFail() }
      XCTAssertEqual(ctx.debugDescription, "Duplicate element at offset 1")
    }
  }

  func testCustomDebugStringConvertible() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.debugDescription, "IdentifiedArray<Int>([1, 2, 3])")
  }

  func testCustomReflectable() {
    let array: IdentifiedArray = [1, 2, 3]
    let mirror = Mirror(reflecting: array)
    XCTAssertEqual(mirror.displayStyle, .collection)
    XCTAssert(mirror.superclassMirror == nil)
    XCTAssertEqual(mirror.children.compactMap { $0.label }.isEmpty, true)
    XCTAssertEqual(mirror.children.map { $0.value as? Int }, array.map { $0 })
  }

  func testCustomStringConvertible() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.description, "[1, 2, 3]")
  }

  func testHashable() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(Set([array]), Set([array, array]))
  }

  func testInitUncheckedUniqueElements() {
    let array = IdentifiedArray(uncheckedUniqueElements: [1, 2, 3])
    XCTAssertEqual(array, [1, 2, 3])
  }

  func testInitUniqueElementsSelf() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(IdentifiedArray(uniqueElements: array), [1, 2, 3])
  }

  func testInitUniqueElementsSubSequence() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(IdentifiedArray(uniqueElements: array[...]), [1, 2, 3])
  }

  func testInitUniqueElements() {
    let array = IdentifiedArray(uniqueElements: [1, 2, 3])
    XCTAssertEqual(array, [1, 2, 3])
  }

  func testSelfInit() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(IdentifiedArray(array), [1, 2, 3])
  }

  func testSubsequenceInit() {
    let array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(IdentifiedArray(array[...]), [1, 2, 3])
  }

  func testAppend() {
    var array: IdentifiedArray = [1, 2, 3]
    var (inserted, index) = array.append(4)
    XCTAssertEqual(inserted, true)
    XCTAssertEqual(index, 3)
    XCTAssertEqual(array, [1, 2, 3, 4])
    (inserted, index) = array.append(2)
    XCTAssertEqual(inserted, false)
    XCTAssertEqual(index, 1)
    XCTAssertEqual(array, [1, 2, 3, 4])
  }

  func testInsert() {
    var array: IdentifiedArray = [1, 2, 3]
    var (inserted, index) = array.insert(0, at: 0)
    XCTAssertEqual(inserted, true)
    XCTAssertEqual(index, 0)
    XCTAssertEqual(array, [0, 1, 2, 3])
    (inserted, index) = array.insert(2, at: 0)
    XCTAssertEqual(inserted, false)
    XCTAssertEqual(index, 2)
    XCTAssertEqual(array, [0, 1, 2, 3])
  }

  func testUpdateAt() {
    var array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.update(2, at: 1), 2)
  }

  func testUpdateOrAppend() {
    var array: IdentifiedArray = [1, 2, 3]
    XCTAssertEqual(array.updateOrAppend(4), nil)
    XCTAssertEqual(array, [1, 2, 3, 4])
    XCTAssertEqual(array.updateOrAppend(2), 2)
  }

  func testUpdateOrInsert() {
    var array: IdentifiedArray = [1, 2, 3]
    var (originalMember, index) = array.updateOrInsert(0, at: 0)
    XCTAssertEqual(originalMember, nil)
    XCTAssertEqual(index, 0)
    XCTAssertEqual(array, [0, 1, 2, 3])
    (originalMember, index) = array.updateOrInsert(2, at: 0)
    XCTAssertEqual(originalMember, 2)
    XCTAssertEqual(index, 2)
    XCTAssertEqual(array, [0, 1, 2, 3])
  }

  func testPartition() {
    var array: IdentifiedArray = [1, 2]

    let index = array.partition { $0.id == 1 }

    XCTAssertEqual(index, 1)
    XCTAssertEqual(array, [2, 1])

    for id in array.ids {
      XCTAssertEqual(id, array[id: id]?.id)
    }
  }

  func testMoveFromOffsetsToOffset() {
    var array: IdentifiedArray = [1, 2, 3]
    array.move(fromOffsets: [0, 2], toOffset: 0)
    XCTAssertEqual(array, [1, 3, 2])

    array = [1, 2, 3]
    array.move(fromOffsets: [0, 2], toOffset: 1)
    XCTAssertEqual(array, [1, 3, 2])

    array = [1, 2, 3]
    array.move(fromOffsets: [0, 2], toOffset: 2)
    XCTAssertEqual(array, [2, 1, 3])
  }

  func testRemoveAtOffsets() {
    var array: IdentifiedArray = [1, 2, 3]
    array.remove(atOffsets: [0, 2])
    XCTAssertEqual(array, [2])
  }
}
