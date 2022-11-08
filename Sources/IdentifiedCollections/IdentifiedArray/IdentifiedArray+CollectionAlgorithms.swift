// Implementations in this file are from the SE-0270 preview package, with minimal changes to work
// with `Foundation.IndexSet` and SwiftUI instead of the proposed `RangeSet` APIs:
//
// https://github.com/apple/swift-se0270-range-set

//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation

extension IdentifiedArray {  // : MutableCollection
  /// Moves all the elements at the specified offsets to the specified destination offset,
  /// preserving ordering.
  ///
  /// - Parameters:
  ///   - source: The offsets of all elements to be moved.
  ///   - destination: The destination offset.
  /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
  @inlinable
  public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
    let lowerCount = distance(from: self.startIndex, to: destination)
    let upperCount = distance(from: destination, to: self.endIndex)
    _ = self._indexedStablePartition(
      count: lowerCount,
      range: self.startIndex..<destination,
      by: { source.contains($0) }
    )
    _ = self._indexedStablePartition(
      count: upperCount,
      range: destination..<self.endIndex,
      by: { !source.contains($0) }
    )
  }
}

extension IdentifiedArray {  // : RangeReplaceableCollection
  /// Removes all the elements at the specified offsets from the collection.
  ///
  /// - Parameter offsets: The offsets of all elements to be removed.
  /// - Complexity: O(*n*) where *n* is the length of the collection.
  @inlinable
  public mutating func remove(atOffsets offsets: IndexSet) {
    guard let firstRange = offsets.rangeView.first else {
      return
    }

    var endOfElementsToKeep = firstRange.lowerBound
    var firstUnprocessed = firstRange.upperBound

    // This performs a half-stable partition based on the ranges in
    // `indices`. At all times, the collection is divided into three
    // regions:
    //
    // - `self[..<endOfElementsToKeep]` contains only elements that will
    //   remain in the collection after this method call.
    // - `self[endOfElementsToKeep..<firstUnprocessed]` contains only
    //   elements that will be removed.
    // - `self[firstUnprocessed...]` contains a mix of elements to remain
    //   and elements to be removed.
    //
    // Each iteration of this loop moves the elements that are _between_
    // two ranges to remove from the third region to the first region.
    for range in offsets.rangeView.dropFirst() {
      let nextLow = range.lowerBound
      while firstUnprocessed != nextLow {
        self.swapAt(endOfElementsToKeep, firstUnprocessed)
        self.formIndex(after: &endOfElementsToKeep)
        self.formIndex(after: &firstUnprocessed)
      }

      firstUnprocessed = range.upperBound
    }

    // After dealing with all the ranges in `indices`, move the elements
    // that are still in the third region down to the first.
    while firstUnprocessed != endIndex {
      self.swapAt(endOfElementsToKeep, firstUnprocessed)
      self.formIndex(after: &endOfElementsToKeep)
      self.formIndex(after: &firstUnprocessed)
    }

    self.removeSubrange(endOfElementsToKeep..<self.endIndex)
  }
}

extension IdentifiedArray {
  /// Moves all elements at the indices satisfying `belongsInSecondPartition`
  /// into a suffix of the collection, preserving their relative order, and
  /// returns the start of the resulting suffix.
  ///
  /// - Complexity: O(*n* log *n*) where *n* is the number of elements.
  /// - Precondition:
  ///   `n == distance(from: range.lowerBound, to: range.upperBound)`
  @inlinable
  mutating func _indexedStablePartition(
    count n: Int,
    range: Range<Index>,
    by belongsInSecondPartition: (Index) throws -> Bool
  ) rethrows -> Index {
    if n == 0 { return range.lowerBound }
    if n == 1 {
      return try belongsInSecondPartition(range.lowerBound)
        ? range.lowerBound
        : range.upperBound
    }
    let h = n / 2
    let i = index(range.lowerBound, offsetBy: h)
    let j = try self._indexedStablePartition(
      count: h,
      range: range.lowerBound..<i,
      by: belongsInSecondPartition)
    let k = try self._indexedStablePartition(
      count: n - h,
      range: i..<range.upperBound,
      by: belongsInSecondPartition)
    return self._rotate(in: j..<k, shiftingToStart: i)
  }

  /// Rotates the elements of the collection so that the element at `middle`
  /// ends up first.
  ///
  /// - Returns: The new index of the element that was first pre-rotation.
  /// - Complexity: O(*n*)
  @discardableResult
  @inlinable
  internal mutating func _rotate(
    in subrange: Range<Index>,
    shiftingToStart middle: Index
  ) -> Index {
    var m = middle
    var s = subrange.lowerBound
    let e = subrange.upperBound

    // Handle the trivial cases
    if s == m { return e }
    if m == e { return s }

    // We have two regions of possibly-unequal length that need to be
    // exchanged.  The return value of this method is going to be the
    // position following that of the element that is currently last
    // (element j).
    //
    //   [a b c d e f g|h i j]   or   [a b c|d e f g h i j]
    //   ^             ^     ^        ^     ^             ^
    //   s             m     e        s     m             e
    //
    var ret = e  // start with a known incorrect result.
    while true {
      // Exchange the leading elements of each region (up to the
      // length of the shorter region).
      //
      //   [a b c d e f g|h i j]   or   [a b c|d e f g h i j]
      //    ^^^^^         ^^^^^          ^^^^^ ^^^^^
      //   [h i j d e f g|a b c]   or   [d e f|a b c g h i j]
      //   ^     ^       ^     ^         ^    ^     ^       ^
      //   s    s1       m    m1/e       s   s1/m   m1      e
      //
      let (s1, m1) = _swapNonemptySubrangePrefixes(s..<m, m..<e)

      if m1 == e {
        // Left-hand case: we have moved element j into position.  if
        // we haven't already, we can capture the return value which
        // is in s1.
        //
        // Note: the STL breaks the loop into two just to avoid this
        // comparison once the return value is known.  I'm not sure
        // it's a worthwhile optimization, though.
        if ret == e { ret = s1 }

        // If both regions were the same size, we're done.
        if s1 == m { break }
      }

      // Now we have a smaller problem that is also a rotation, so we
      // can adjust our bounds and repeat.
      //
      //    h i j[d e f g|a b c]   or    d e f[a b c|g h i j]
      //         ^       ^     ^              ^     ^       ^
      //         s       m     e              s     m       e
      s = s1
      if s == m { m = m1 }
    }

    return ret
  }

  /// Swaps the elements of the two given subranges, up to the upper bound of
  /// the smaller subrange. The returned indices are the ends of the two
  /// ranges that were actually swapped.
  ///
  ///     Input:
  ///     [a b c d e f g h i j k l m n o p]
  ///      ^^^^^^^         ^^^^^^^^^^^^^
  ///      lhs             rhs
  ///
  ///     Output:
  ///     [i j k l e f g h a b c d m n o p]
  ///             ^               ^
  ///             p               q
  ///
  /// - Precondition: !lhs.isEmpty && !rhs.isEmpty
  /// - Postcondition: For returned indices `(p, q)`:
  ///
  ///   - distance(from: lhs.lowerBound, to: p) == distance(from:
  ///     rhs.lowerBound, to: q)
  ///   - p == lhs.upperBound || q == rhs.upperBound
  @inlinable
  internal mutating func _swapNonemptySubrangePrefixes(
    _ lhs: Range<Index>, _ rhs: Range<Index>
  ) -> (Index, Index) {
    assert(!lhs.isEmpty)
    assert(!rhs.isEmpty)

    var p = lhs.lowerBound
    var q = rhs.lowerBound
    repeat {
      self.swapAt(p, q)
      self.formIndex(after: &p)
      self.formIndex(after: &q)
    } while p != lhs.upperBound && q != rhs.upperBound
    return (p, q)
  }
}
