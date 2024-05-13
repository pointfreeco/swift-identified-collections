import IdentifiedCollections
import XCTest

final class IdentifiedArrayCollectionOperationsTests: XCTestCase {
  func testReverse() {
    assertElementsEqual { $0.reverse() }
  }
  func testSort() {
    assertElementsEqual { $0.sort() }
  }
  #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    func testSortUsing() {
      assertElementsEqual { $0.sort(using: KeyPathComparator(\.count)) }
    }
  #endif
}

private struct Item: Identifiable, Comparable, Equatable {
  let id = UUID()
  var count: Int

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.count < rhs.count
  }
}

private protocol TestCollection<Element>:
MutableCollection, RandomAccessCollection, RangeReplaceableCollection {}

extension Array: TestCollection {}
extension IdentifiedArray: TestCollection where Element: Identifiable, Element.ID == ID {}

private func assertElementsEqual(
  after operation: (inout (any TestCollection<Item>)) -> Void,
  file: StaticString = #file,
  line: UInt = #line
) {
  for n in 0...10 {
    let size = Int(pow(Double(n), 2))
    for _ in 1...10 {
      var identifiedArray: IdentifiedArrayOf<Item> = []
      for _ in 0..<size {
        identifiedArray.append(Item(count: .random(in: -1_000...1_000)))
      }
      var anyIdentifiedArray = identifiedArray as any TestCollection<Item>
      var anyArray = Array(identifiedArray) as any TestCollection<Item>
      operation(&anyIdentifiedArray)
      operation(&anyArray)
      XCTAssert(
        anyIdentifiedArray.elementsEqual(anyArray),
        """
        (\(anyIdentifiedArray)) does not equal control (\(anyArray))
        """,
        file: file,
        line: line
      )
      identifiedArray = anyIdentifiedArray as! IdentifiedArrayOf<Item>
      XCTAssert(
        identifiedArray.ids.elementsEqual(identifiedArray.map(\.id)),
        """
        (\(identifiedArray.ids)) keys does not equal IDs (\(identifiedArray.map(\.id)))
        """,
        file: file,
        line: line
      )
      if size == 0 {
        continue
      }
    }
  }
}
