import OrderedCollections

/// An ordered collection of identifiable elements.
///
/// Similar to the standard `Array`, identified arrays maintain their elements in a particular
/// user-specified order, and they support efficient random access traversal of their members.
/// However, unlike `Array`, identified arrays introduce the ability to uniquely identify elements,
/// using a hash table to ensure that no two elements have the same identity, and to efficiently
/// look up elements corresponding to specific identifiers.
///
/// ``IdentifiedArray`` is a useful alternative to `Array` when you need to be able to efficiently
/// access unique elements by a stable identifier. It is also a useful alternative to `OrderedSet`,
/// where the `Hashable` requirement may be too strict.
///
/// You can create an identified array with any element type that conforms to the `Identifiable`
/// protocol.
///
/// ```swift
/// struct User: Identifiable { var id: String }
/// var users: IdentifiedArray = [User(id: "u_42"), User(id: "u_1729")]
/// ```
///
/// Or you can provide a key path that describes an element's identity:
///
/// ```swift
/// var numbers = IdentifiedArray(id: \Int.self)
/// ```
///
/// # Motivation
///
/// When modeling a collection of elements in your application's state, it is easy to reach for a
/// standard `Array`. However, as your application becomes more complex, this approach can break
/// down in many ways, including accidentally making mutations to the wrong elements or even
/// crashing. 😬
///
/// For example, if you were building a "Todos" application in SwiftUI, you might model an
/// individual todo in an identifiable value type:
///
/// ```swift
/// struct Todo: Identifiable {
///   var description = ""
///   let id: UUID
///   var isComplete = false
/// }
/// ```
///
/// And you would hold an array of these todos as a published field in your app's view model:
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   @Published var todos: [Todo] = []
/// }
/// ```
///
/// A view can render a list of these todos quite simply, and because they are identifiable we can
/// even omit the `id` parameter of `List`:
///
/// ```swift
/// struct TodosView: View {
///   @ObservedObject var viewModel: TodosViewModel
///
///   var body: some View {
///     List(self.viewModel.todos) { todo in
///       ...
///     }
///   }
/// }
/// ```
///
/// If your deployment target is set to the latest version of SwiftUI, you may be tempted to pass
/// along a binding to the list so that each row is given mutable access to its todo. This will work
/// for simple cases, but as soon as you introduce side effects, like API clients or analytics, or
/// want to write unit tests, you must push this logic into a view model, instead. And that means
/// each row must be able to communicate its actions back to the view model.
///
/// You could do so by introducing some endpoints on the view model, like when a row's completed
/// toggle is changed:
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   ...
///   func todoCheckboxToggled(at id: Todo.ID) {
///     guard let index = self.todos.firstIndex(where: { $0.id == id })
///     else { return }
///
///     self.todos[index].isComplete.toggle()
///     // TODO: Update todo on backend using an API client
///   }
/// }
/// ```
///
/// This code is simple enough, but it can require a full traversal of the array to do its job.
///
/// Perhaps it would be more performant for a row to communicate its index back to the view model
/// instead, and then it could mutate the todo directly via its index subscript. But this makes the
/// view more complicated:
///
/// ```swift
/// List(self.viewModel.todos.enumerated(), id: \.element.id) { index, todo in
///   ...
/// }
/// ```
///
/// This isn't so bad, but at the moment it doesn't even compile. An
/// [evolution proposal](https://github.com/apple/swift-evolution/blob/main/proposals/0312-indexed-and-enumerated-zip-collections.md)
/// may change that soon, but in the meantime `List` and `ForEach` must be passed a
/// `RandomAccessCollection`, which is perhaps most simply achieved by constructing another array:
///
/// ```swift
/// List(Array(self.viewModel.todos.enumerated()), id: \.element.id) { index, todo in
///   ...
/// }
/// ```
///
/// This compiles, but we've just moved the performance problem to the view: every time this body is
/// evaluated there's the possibility a whole new array is being allocated.
///
/// But even if it were possible to pass an enumerated collection directly to these views,
/// identifying an element of mutable state by an index introduces a number of other problems.
///
/// While it's true that we can greatly simplify and improve the performance of any view model
/// methods that mutate an element through its index subscript:
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   ...
///   func todoCheckboxToggled(at index: Int) {
///     self.todos[index].isComplete.toggle()
///     // TODO: sync with API
///   }
/// }
/// ```
///
/// Any asynchronous work that we add to this endpoint must take great care in _not_ using this
/// index later on. An index is not a stable identifier: todos can be moved and removed at any time,
/// and an index identifying "Buy lettuce" at one moment may identify "Call Mom" the next, or worse,
/// may be a completely invalid index and crash your application!
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   ...
///   func todoCheckboxToggled(at index: Int) async {
///     self.todos[index].isComplete.toggle()
///
///     do {
///       // ❌ Could update the wrong todo, or crash!
///       self.todos[index] = try await self.apiClient.updateTodo(self.todos[index])
///     } catch {
///       // Handle error
///     }
///   }
/// }
/// ```
///
/// Whenever you need to access a particular todo after performing some asynchronous work, you
/// _must_ do the work of traversing the array:
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   ...
///   func todoCheckboxToggled(at index: Int) async {
///     self.todos[index].isComplete.toggle()
///
///     // 1️⃣ Get a reference to the todo's id before kicking off the async work
///     let id = self.todos[index].id
///
///     do {
///       // 2️⃣ Update the todo on the backend
///       let updatedTodo = try await self.apiClient.updateTodo(self.todos[index])
///
///       // 3️⃣ Find the updated index of the todo after the async work is done
///       let updatedIndex = self.todos.firstIndex(where: { $0.id == id })!
///
///       // 4️⃣ Update the correct todo
///       self.todos[updatedIndex] = updatedTodo
///     } catch {
///       // Handle error
///     }
///   }
/// }
/// ```
///
/// Identified collections are designed to solve all of these problems by providing data structures
/// for working with collections of identifiable elements in an ergonomic, performant way.
///
/// Most of the time, you can simply swap an `Array` out for an ``IdentifiedArray``:
///
/// ```swift
/// import IdentifiedCollections
///
/// class TodosViewModel: ObservableObject {
///   @Published var todos: IdentifiedArrayOf<Todo> = []
///   ...
/// }
/// ```
///
/// Here we use ``IdentifiedArrayOf`` generic over `Todo` as a shorthand for
/// `IdentifiedArray<Todo.ID, Todo>`.
///
/// And then you can mutate an element directly via its id-based subscript, no traversals needed,
/// even after asynchronous work is performed:
///
/// ```swift
/// class TodosViewModel: ObservableObject {
///   ...
///   func todoCheckboxToggled(at id: Todo.ID) async {
///     self.todos[id: id]?.isComplete.toggle()
///
///     do {
///       // 1️⃣ Update todo on backend and mutate it in the todos identified array.
///       self.todos[id: id] = try await self.apiClient.updateTodo(self.todos[id: id]!)
///     } catch {
///       // Handle error
///     }
///
///     // No step 2️⃣ 😆
///   }
/// }
/// ```
///
/// You can also simply pass the identified array to views like `List` and `ForEach` without any
/// complications:
///
/// ```swift
/// List(self.viewModel.todos) { todo in
///   ...
/// }
/// ```
///
/// # Sequence and Collection Operations
///
/// Identified arrays are random-access collections. Members are assigned integer indices, with the
/// first element always being at index `0`.
///
/// # Performance
///
/// Like the standard `Dictionary` type, the performance of hashing operations in
/// ``IdentifiedArray`` is highly sensitive to the quality of hashing implemented by the `ID`
/// type. Failing to correctly implement hashing can easily lead to unacceptable performance, with
/// the severity of the effect increasing with the size of the underlying hash table.
///
/// In particular, if a certain set of elements all produce the same hash value, then hash table
/// lookups regress to searching an element in an unsorted array, i.e., a linear operation. To
/// ensure hashed collection types exhibit their target performance, it is important to ensure that
/// such collisions cannot be induced merely by adding a particular list of members to the set.
///
/// The easiest way to achieve this is to make sure `ID` implements hashing following `Hashable`'s
/// documented best practices. The conformance must implement the `hash(into:)` requirement, and
/// every bit of information that is compared in `==` needs to be combined into the supplied
/// `Hasher` value. When used correctly, `Hasher` produces high-quality, randomly seeded hash values
/// that prevent repeatable hash collisions.
///
/// When `ID` implements `Hashable` correctly, testing for membership in an ordered set is expected
/// to take O(1) equality checks on average. Hash collisions can still occur organically, so the
/// worst-case lookup performance is technically still O(*n*) (where *n* is the size of the set);
/// however, long lookup chains are unlikely to occur in practice.
///
/// ## Implementation Details
///
/// An identified array consists of an ordered dictionary of id-element pairs. An element's id
/// should not be mutated in place, as it will drift from its associated dictionary key. Identified
/// array is designed to avoid this invariant, with the exception of its *id-based* subscript.
/// Mutating an element's id will result in a runtime error.
public struct IdentifiedArray<ID: Hashable, Element> {
  public let id: KeyPath<Element, ID>

  // NB: Captures identity access. Direct access to `Identifiable`'s `.id` property is faster than
  //     key path access.
  @usableFromInline
  var _id: (Element) -> ID

  @usableFromInline
  var _dictionary: OrderedDictionary<ID, Element>

  /// A read-only collection view for the elements contained in this array, as an `Array`.
  ///
  /// - Complexity: O(1)
  @inlinable
  @inline(__always)
  public var elements: [Element] { self._dictionary.values.elements }

  @usableFromInline
  init(
    id: KeyPath<Element, ID>,
    _id: @escaping (Element) -> ID,
    _dictionary: OrderedDictionary<ID, Element>
  ) {
    self.id = id
    self._id = _id
    self._dictionary = _dictionary
  }

  @inlinable
  public func contains(_ element: Element) -> Bool {
    self._dictionary[self._id(element)] != nil
  }

  /// Returns the index for the given id.
  ///
  /// If an element identified by the given id is found in the array, this method returns an index
  /// into the array that corresponds to the element.
  ///
  /// ```swift
  /// struct User: Identifiable { var id: String }
  /// let users: IdentifiedArray = [
  ///   User(id: "u_42"),
  ///   User(id: "u_1729"),
  /// ]
  /// users.index(id: "u_1729") // 1
  /// users.index(id: "u_1337") // nil
  /// ```
  ///
  /// - Parameter id: The id to find in the array.
  /// - Returns: The index for the element identified by `id` if found in the array; otherwise,
  ///   `nil`.
  /// - Complexity: Expected to be O(1) on average, if `ID` implements high-quality hashing.
  @inlinable
  @inline(__always)
  public func index(id: ID) -> Int? {
    self._dictionary.index(forKey: id)
  }

  /// Removes the given element from the array.
  ///
  /// If the element is found in the array, this method returns the element.
  ///
  /// If the element isn't found in the array, `remove` returns `nil`.
  ///
  /// - Parameter element: The element to remove.
  /// - Returns: The value that was removed, or `nil` if the element was not present in the array.
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func remove(_ element: Element) -> Element? {
    self._dictionary.removeValue(forKey: self._id(element))
  }

  /// Removes the element identified by the given id from the array.
  ///
  /// ```swift
  /// struct User: Identifiable { var id: String }
  /// let users: IdentifiedArray = [
  ///   User(id: "u_42"),
  ///   User(id: "u_1729"),
  /// ]
  /// users.remove(id: "u_1729") // User(id: "u_1729")
  /// users                      // [User(id: "u_42")]
  /// users.remove(id: "u_1337") // nil
  /// ```
  ///
  /// - Parameter id: The id of the element to be removed from the array.
  /// - Returns: The element that was removed, or `nil` if the element was not present in the array.
  /// - Complexity: O(`count`)
  @inlinable
  @discardableResult
  public mutating func remove(id: ID) -> Element? {
    self._dictionary.removeValue(forKey: id)
  }
}

/// A convenience type alias that specifies an ``IdentifiedArray`` by an element conforming to the
/// `Identifiable` protocol.
///
/// ```swift
/// struct User: Identifiable { var id: String }
/// var users: IdentifiedArrayOf<User> = []
/// ```
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public typealias IdentifiedArrayOf<Element> = IdentifiedArray<Element.ID, Element>
where Element: Identifiable
