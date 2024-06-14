import CollectionsBenchmark
import IdentifiedCollections

#if $RetroactiveAttribute
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Int: @retroactive Identifiable { public var id: Self { self } }
#else
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  extension Int: Identifiable { public var id: Self { self } }
#endif

if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
  var benchmark = Benchmark(title: "Identified Collections Benchmark")

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> init from range",
    input: Int.self
  ) { size in
    blackHole(IdentifiedArray(uniqueElements: 0..<size))
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> init from unsafe buffer",
    input: [Int].self
  ) { input in
    input.withUnsafeBufferPointer { buffer in
      blackHole(IdentifiedArray(uniqueElements: buffer))
    }
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> init(uncheckedUniqueElements:) from range",
    input: Int.self
  ) { size in
    blackHole(IdentifiedArray(uniqueElements: 0..<size))
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> random-access offset lookups",
    input: ([Int], [Int]).self
  ) { input, lookups in
    let array = IdentifiedArray(uniqueElements: input)
    return { timer in
      for i in lookups {
        blackHole(array[i])
      }
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> sequential iteration",
    input: [Int].self
  ) { input in
    let array = IdentifiedArray(uniqueElements: input)
    return { timer in
      for i in array {
        blackHole(i)
      }
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> successful contains",
    input: ([Int], [Int]).self
  ) { input, lookups in
    let array = IdentifiedArray(uniqueElements: input)
    return { timer in
      for i in lookups {
        precondition(array.contains(i))
      }
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> unsuccessful contains",
    input: ([Int], [Int]).self
  ) { input, lookups in
    let array = IdentifiedArray(uniqueElements: input)
    let lookups = lookups.map { $0 + input.count }
    return { timer in
      for i in lookups {
        precondition(!array.contains(i))
      }
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> random swaps",
    input: [Int].self
  ) { input in
    return { timer in
      var array = IdentifiedArray(uniqueElements: 0..<input.count)
      timer.measure {
        for i in input.indices {
          array.swapAt(i, input[i])
        }
      }
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> partitioning around middle",
    input: [Int].self
  ) { input in
    return { timer in
      let pivot = input.count / 2
      var array = IdentifiedArray(uniqueElements: input)
      timer.measure {
        let r = array.partition(by: { $0 >= pivot })
        precondition(r == pivot)
      }
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> sort",
    input: [Int].self
  ) { input in
    return { timer in
      var array = IdentifiedArray(uniqueElements: input)
      timer.measure {
        array.sort()
      }
      precondition(array.elementsEqual(0..<input.count))
    }
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> append",
    input: [Int].self
  ) { input in
    var array: IdentifiedArrayOf<Int> = []
    for i in input {
      array.append(i)
    }
    precondition(array.count == input.count)
    blackHole(array)
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> append, reserving capacity",
    input: [Int].self
  ) { input in
    var array: IdentifiedArray<Int, Int> = []
    array.reserveCapacity(input.count)
    for i in input {
      array.append(i)
    }
    precondition(array.count == input.count)
    blackHole(array)
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> prepend",
    input: [Int].self
  ) { input in
    var array: IdentifiedArray<Int, Int> = []
    for i in input {
      _ = array.insert(i, at: 0)
    }
    blackHole(array)
  }

  benchmark.addSimple(
    title: "IdentifiedArray<Int, Int> prepend, reserving capacity",
    input: [Int].self
  ) { input in
    var array: IdentifiedArray<Int, Int> = []
    array.reserveCapacity(input.count)
    for i in input {
      _ = array.insert(i, at: 0)
    }
    blackHole(array)
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> random insertions, reserving capacity",
    input: Benchmark.Insertions.self
  ) { insertions in
    return { timer in
      let insertions = insertions.values
      var array: IdentifiedArray<Int, Int> = []
      array.reserveCapacity(insertions.count)
      timer.measure {
        for i in insertions.indices {
          _ = array.insert(i, at: insertions[i])
        }
      }
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> remove",
    input: ([Int], [Int]).self
  ) { input, removals in
    return { timer in
      var array = IdentifiedArray(uniqueElements: input)
      timer.measure {
        for i in removals {
          array.remove(i)
        }
      }
      precondition(array.isEmpty)
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> removeLast",
    input: Int.self
  ) { size in
    return { timer in
      var array = IdentifiedArray(uniqueElements: 0..<size)
      timer.measure {
        for _ in 0..<size {
          array.removeLast()
        }
      }
      precondition(array.isEmpty)
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> removeFirst",
    input: Int.self
  ) { size in
    return { timer in
      var array = IdentifiedArray(uniqueElements: 0..<size)
      timer.measure {
        for _ in 0..<size {
          array.removeFirst()
        }
      }
      precondition(array.isEmpty)
      blackHole(array)
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> diff computation",
    input: ([Int], [Int]).self
  ) { pa, pb in
    let a = IdentifiedArray(uniqueElements: pa)
    let b = IdentifiedArray(uniqueElements: pb)
    return { timer in
      timer.measure {
        blackHole(b.difference(from: a))
      }
    }
  }

  benchmark.add(
    title: "IdentifiedArray<Int, Int> diff application",
    input: ([Int], [Int]).self
  ) { a, b in
    let d = IdentifiedArray(uniqueElements: b).difference(from: IdentifiedArray(uniqueElements: a))
    return { timer in
      timer.measure {
        blackHole(a.applying(d))
      }
    }
  }

  benchmark.main()
}
