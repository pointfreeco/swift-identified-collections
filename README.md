# Swift Identified Collections

[![CI](https://github.com/pointfreeco/swift-identified-collections/workflows/CI/badge.svg)](https://actions-badge.atrox.dev/pointfreeco/swift-identified-collections/goto)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-identified-collections%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/pointfreeco/swift-identified-collections)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpointfreeco%2Fswift-identified-collections%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/pointfreeco/swift-identified-collections)

A library of data structures for working with collections of identifiable elements in an ergonomic, performant way.

## Motivation

When modeling a collection of elements in your application's state, it is easy to reach for a standard `Array`. However, as your application becomes more complex, this approach can break down in many ways, including accidentally making mutations to the wrong elements or even crashing. 😬

For example, if you were building a "Todos" application in SwiftUI, you might model an individual todo in an identifiable value type:

```swift
struct Todo: Identifiable {
  var description = ""
  let id: UUID
  var isComplete = false
}
```

And you would hold an array of these todos as a published field in your app's view model:

```swift
class TodosViewModel: ObservableObject {
  @Published var todos: [Todo] = []
}
```

A view can render a list of these todos quite simply, and because they are identifiable we can even omit the `id` parameter of `List`:

```swift
struct TodosView: View {
  @ObservedObject var viewModel: TodosViewModel
  
  var body: some View {
    List(self.viewModel.todos) { todo in
      ...
    }
  }
}
```

If your deployment target is set to the latest version of SwiftUI, you may be tempted to pass along a binding to the list so that each row is given mutable access to its todo. This will work for simple cases, but as soon as you introduce side effects, like API clients or analytics, or want to write unit tests, you must push this logic into a view model, instead. And that means each row must be able to communicate its actions back to the view model.

You could do so by introducing some endpoints on the view model, like when a row's completed toggle is changed:

```swift
class TodosViewModel: ObservableObject {
  ...
  func todoCheckboxToggled(at id: Todo.ID) {
    guard let index = self.todos.firstIndex(where: { $0.id == id })
    else { return }
    
    self.todos[index].isComplete.toggle()
    // TODO: Update todo on backend using an API client
  }
}
```

This code is simple enough, but it can require a full traversal of the array to do its job.

Perhaps it would be more performant for a row to communicate its index back to the view model instead, and then it could mutate the todo directly via its index subscript. But this makes the view more complicated:

```swift
List(self.viewModel.todos.enumerated(), id: \.element.id) { index, todo in
  ...
}
```

This isn't so bad, but at the moment it doesn't even compile. An [evolution proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0312-indexed-and-enumerated-zip-collections.md) may change that soon, but in the meantime `List` and `ForEach` must be passed a `RandomAccessCollection`, which is perhaps most simply achieved by constructing another array:

```swift
List(Array(self.viewModel.todos.enumerated()), id: \.element.id) { index, todo in
  ...
}
```

This compiles, but we've just moved the performance problem to the view: every time this body is evaluated there's the possibility a whole new array is being allocated.

But even if it were possible to pass an enumerated collection directly to these views, identifying an element of mutable state by an index introduces a number of other problems.

While it's true that we can greatly simplify and improve the performance of any view model methods that mutate an element through its index subscript:

```swift
class TodosViewModel: ObservableObject {
  ...
  func todoCheckboxToggled(at index: Int) {
    self.todos[index].isComplete.toggle()
    // TODO: Update todo on backend using an API client
  }
}
```

Any asynchronous work that we add to this endpoint must take great care in _not_ using this index later on. An index is not a stable identifier: todos can be moved and removed at any time, and an index identifying "Buy lettuce" at one moment may identify "Call Mom" the next, or worse, may be a completely invalid index and crash your application!

```swift
class TodosViewModel: ObservableObject {
  ...
  func todoCheckboxToggled(at index: Int) async {
    self.todos[index].isComplete.toggle()
    
    do {
      // ❌ Could update the wrong todo, or crash!
      self.todos[index] = try await self.apiClient.updateTodo(self.todos[index]) 
    } catch {
      // Handle error
    }
  }
}
```

Whenever you need to access a particular todo after performing some asynchronous work, you _must_ do the work of traversing the array:

```swift
class TodosViewModel: ObservableObject {
  ...
  func todoCheckboxToggled(at index: Int) async {
    self.todos[index].isComplete.toggle()
    
    // 1️⃣ Get a reference to the todo's id before kicking off the async work
    let id = self.todos[index].id
  
    do {
      // 2️⃣ Update the todo on the backend
      let updatedTodo = try await self.apiClient.updateTodo(self.todos[index])
              
      // 3️⃣ Find the updated index of the todo after the async work is done
      let updatedIndex = self.todos.firstIndex(where: { $0.id == id })!
      
      // 4️⃣ Update the correct todo
      self.todos[updatedIndex] = updatedTodo
    } catch {
      // Handle error
    }
  }
}
```

## Introducing: identified collections

Identified collections are designed to solve all of these problems by providing data structures for working with collections of identifiable elements in an ergonomic, performant way.

Most of the time, you can simply swap an `Array` out for an `IdentifiedArray`:

```swift
import IdentifiedCollections

class TodosViewModel: ObservableObject {
  @Published var todos: IdentifiedArrayOf<Todo> = []
  ...
}
```

And then you can mutate an element directly via its id-based subscript, no traversals needed, even after asynchronous work is performed:

```swift
class TodosViewModel: ObservableObject {
  ...
  func todoCheckboxToggled(at id: Todo.ID) async {
    self.todos[id: id]?.isComplete.toggle()
    
    do {
      // 1️⃣ Update todo on backend and mutate it in the todos identified array.
      self.todos[id: id] = try await self.apiClient.updateTodo(self.todos[id: id]!)
    } catch {
      // Handle error
    }

    // No step 2️⃣ 😆
  }
}
```

You can also simply pass the identified array to views like `List` and `ForEach` without any complications:

```swift
List(self.viewModel.todos) { todo in
  ...
}
```

Identified arrays are designed to integrate with SwiftUI applications, as well as applications written in [the Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Design

`IdentifiedArray` is a lightweight wrapper around the [`OrderedDictionary`](https://github.com/apple/swift-collections/blob/main/Documentation/OrderedDictionary.md) type from Apple's [Swift Collections](https://github.com/apple/swift-collections). It shares many of the same performance characteristics and design considerations, but is better adapted to solving the problem of holding onto a collection of _identifiable_ elements in your application's state.

`IdentifiedArray` does not expose any of the details of `OrderedDictionary` that may lead to breaking invariants. For example an `OrderedDictionary<ID, Identifiable>` may freely hold a value whose identifier does not match its key or multiple values could have the same id, and `IdentifiedArray` does not allow for these situations.

And unlike [`OrderedSet`](https://github.com/apple/swift-collections/blob/main/Documentation/OrderedSet.md), `IdentifiedArray` does not require that its `Element` type conforms to the `Hashable` protocol, which may be difficult or impossible to do, and introduces questions around the quality of hashing, etc.

`IdentifiedArray` does not even require that its `Element` conforms to `Identifiable`. Just as SwiftUI's `List` and `ForEach` views take an `id` key path to an element's identifier, `IdentifiedArray`s can be constructed with a key path:

```swift  
var numbers = IdentifiedArray(id: \Int.self)
```

## Performance

`IdentifiedArray` is designed to match the performance characteristics of `OrderedDictionary`. It has been benchmarked with [Swift Collections Benchmark](https://github.com/apple/swift-collections-benchmark):

![](.github/benchmark.png)

## Installation

You can add Identified Collections to an Xcode project by adding it as a package dependency.

> https://github.com/pointfreeco/swift-identified-collections

If you want to use Identified Collections in a [SwiftPM](https://swift.org/package-manager/) project, it's as simple as adding a `dependencies` clause to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.1.0")
],
```

## Documentation

The latest documentation for Identified Collections' APIs is available [here](https://pointfreeco.github.io/swift-identified-collections/).

## Interested in learning more?

These concepts (and more) are explored thoroughly in [Point-Free](https://www.pointfree.co), a video series exploring functional programming and Swift hosted by [Brandon Williams](https://github.com/mbrandonw) and [Stephen Celis](https://github.com/stephencelis).

Usage of `IdentifiedArray` in [the Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) was explored in the following [Point-Free](https://www.pointfree.co) episode:

  - [Episode 148](https://www.pointfree.co/episodes/ep148-derived-behavior-collections): Derived Behavior: Collections

<a href="https://www.pointfree.co/episodes/ep148-derived-behavior-collections">
  <img alt="video poster image" src="https://d3rccdn33rt8ze.cloudfront.net/episodes/0148.jpeg" width="480">
</a>

## License

All modules are released under the MIT license. See [LICENSE](LICENSE) for details.
