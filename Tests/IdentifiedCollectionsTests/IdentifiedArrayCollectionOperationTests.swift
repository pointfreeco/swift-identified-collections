import IdentifiedCollections
import XCTest

final class IdentifiedArrayCollectionOperationsTests: XCTestCase {
  func testMax() {
    assertElementsEqual { $0.max() }
    assertElementsEqual { $0.max(by: >) }
  }
  func testMin() {
    assertElementsEqual { $0.min() }
    assertElementsEqual { $0.min(by: >) }
  }
  func testRemoveFirst() {
    assertElementsEqual { $0.isEmpty ? nil : $0.removeFirst() }
  }
  func testRemoveLast() {
    assertElementsEqual { $0.isEmpty ? nil : $0.removeLast() }
  }
  func testReverse() {
    assertElementsEqual { $0.reverse() }
  }
  func testShuffleUsing() {
    var seed: UInt64 = 0
    assertElementsEqual {
      var rng = LCRNG(seed: seed)
      $0.shuffle(using: &rng)
    } setUp: {
      seed = .random(in: .min ... .max)
    }
  }
  func testSort() {
    assertElementsEqual { $0.sort() }
    assertElementsEqual { $0.sort(by: >) }
  }
  #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    func testSortUsing() {
      assertElementsEqual { $0.sort(using: KeyPathComparator(\.count)) }
      assertElementsEqual { $0.sort(using: KeyPathComparator(\.count, order: .reverse)) }
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

private func assertElementsEqual<Result>(
  after operation: (inout (any TestCollection<Item>)) -> Result,
  setUp: () -> Void = {},
  file: StaticString = #file,
  line: UInt = #line
) {
  for n in 0...10 {
    let size = Int(pow(Double(n), 2))
    for _ in 1...10 {
      setUp()
      var identifiedArray: IdentifiedArrayOf<Item> = []
      for _ in 0..<size {
        identifiedArray.append(Item(count: .random(in: -1_000...1_000)))
      }
      var anyIdentifiedArray = identifiedArray as any TestCollection<Item>
      var anyArray = Array(identifiedArray) as any TestCollection<Item>
      let lhs = operation(&anyIdentifiedArray)
      let rhs = operation(&anyArray)
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
      if let lhs = lhs as? any Equatable {
        func open<LHS: Equatable>(_ lhs: LHS) {
          if let rhs = rhs as? LHS {
            XCTAssertEqual(lhs, rhs, file: file, line: line)
          }
        }
        open(lhs)
      }
      if size == 0 {
        continue
      }
    }
  }
}

struct LCRNG: RandomNumberGenerator {
  var seed: UInt64
  init(seed: UInt64 = 0) {
    self.seed = seed
  }
  mutating func next() -> UInt64 {
    self.seed = 2_862_933_555_777_941_757 &* self.seed &+ 3_037_000_493
    return self.seed
  }
}
