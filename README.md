# JSON Insight for SwiftUI

**A macOS App for Viewing, Formatting, and Understanding JSON Data, Built with Modern SwiftUI Techniques.**

[![SwiftUI](https://img.shields.io/badge/SwiftUI-Learner%20Friendly-orange?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)
[![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY)
<!-- Add a LICENSE file -->

---
Copyright (c) 2025 Cong Le. All Rights Reserved.

---


Dive into the structure of your JSON data with **JSON Insight for SwiftUI**. This simple yet effective macOS application provides two complementary views: a raw text editor and an interactive, hierarchical tree viewer. It serves as a practical utility and a learning resource, demonstrating several core concepts in SwiftUI development for macOS.

---

## Screenshots/DEMO/TODO

*(It's highly recommended to add a screenshot or GIF here showing the app in action, perhaps with the text and viewer modes visible!)*

```
+-------------------------------------+-------------------------------------+
|         Text Editor View            |           Tree Viewer View          |
|-------------------------------------|-------------------------------------+
| {                                   | ▼ 📁 specification: "ECMA-404"      |
|   "specification": "ECMA-404",      |   📄 name: "Example JSON"           |
|   "name": "Example JSON",           |   #️⃣ version: 1.0                  |
|   "version": 1.0,                   |   ✅ enabled: true                  |
|   "enabled": true,                  |   ▼  L items: [7 items]            |
|   "items": [                        |   |  ▼ 📁 [0]: {3 items}            |
|     {"id": 1, "value": "apple"...}, |   |  |   #️⃣ id: 1                   |
|     {"id": 2, "value": "banana"...},|   |  |   📄 value: "apple"         |
|     null,                           |   |  |   ▼ L [tags]: [2 items]     |
|     [10, 20.5, ...],                |   |  |   |   📄 [0]: "fruit"     |
|     {},                             |   |  |   |   📄 [1]: "red"       |
|     "string item",                  |   |  ▼ 📁 [1]: {3 items}            |
|     false                           |   |  |   #️⃣ id: 2                   |
|   ],                                |   |  |   📄 value: "banana"        |
|   "settings": {...},                |   |  |   ▼ L [tags]: [3 items]     |
|   ...                               |   |  |   |   📄 [0]: "fruit"     |
| }                                   |   |  |   |   📄 [1]: "yellow"    |
|                                     |   |  |   |   🚫 [2]: null          |
|                                     |   |  🚫 [2]: null                  |
|                                     |   |  ▼ L [3]: [4 items]            |
|                                     |   |  |   #️⃣ [0]: 10               |
|                                     |   |  |   #️⃣ [1]: 20.5             |
|                                     |   |  |   #️⃣ [2]: -3                 |
|                                     |   |  |   #️⃣ [3]: 40               |
|                                     |   |  📁 [4]: {}                    |
|                                     |   |  📄 [5]: "string item"         |
|                                     |   |  ❌ [6]: false                 |
|                                     |   ▼ 📁 settings: {4 items}          |
|                                     |   ...                               |
+-------------------------------------+-------------------------------------+
```
*(Textual representation of a possible UI)*

---

## Key Features

*   **Dual View Mode:** Seamlessly switch between a raw `TextEditor` and a structured `JSONViewer`.
*   **Hierarchical Tree Viewer:** Explore nested JSON objects and arrays with clear visual hierarchy, type icons, and keys/indices.
*   **JSON Formatting:** Pretty-print your JSON with indentation and sorted keys for improved readability.
*   **JSON Compacting:** Remove unnecessary whitespace to create a compact JSON string.
*   **Syntax Validation:** Basic JSON validation occurs when switching to the viewer or performing actions. Errors are displayed clearly.
*   **File Loading:** Load JSON data directly from `.json` files using a standard macOS open panel.
*   **Standard Clipboard Actions:** Copy, Paste, Cut (within text editor context), and Select All functionality integrated.
*   **Clear Functionality:** Quickly clear the text editor content.

---

## Technical Highlights & Techniques Showcased

This project serves as a great example for learning and applying various SwiftUI and macOS development techniques:

*   **SwiftUI App Structure:** Demonstrates `@main` App protocol, `WindowGroup`, and basic Scene setup.
*   **State Management:** Uses `@State` for managing UI state like the current JSON text, parsed items, selected view, and alert presentation.
*   **View Composition:** Builds the UI by composing smaller, reusable SwiftUI Views (`ContentView`, `JSONViewer`, `JSONRow`, `ErrorView`, `EmptyViewPlaceholder`).
*   **Conditional Rendering:** Uses `if/else` statements within the `ContentView` body to switch between the `TextEditor` and `JSONViewer`.
*   **Hierarchical `List`:** Leverages SwiftUI's `List` with the `children:` parameter to naturally display the recursive `JSONItem` data structure.
*   **Custom Data Structures:** Defines a custom `Identifiable` struct (`JSONItem`) perfectly suited for driving the hierarchical `List`.
*   **JSON Parsing:** Utilizes `JSONSerialization` for parsing raw JSON data from `String` to Swift objects (`Any`), including options like `.fragmentsAllowed`.
*   **JSON Generation:** Employs `JSONSerialization` to generate formatted (`.prettyPrinted`, `.sortedKeys`) and compact JSON strings.
*   **Recursion:** Implements a clean recursive function (`createSingleJSONItem`) to traverse the parsed JSON `Any` object and build the `JSONItem` tree structure.
*   **SwiftUI `Toolbar`:** Integrates standard macOS toolbar items (`ToolbarItemGroup`, `Picker`, `Button`, `Label`, `Spacer`) for actions and view switching.
*   **macOS Integration:**
    *   Uses `NSOpenPanel` with `UTType.json` for file loading.
    *   Interacts with `NSPasteboard` for clipboard operations.
    *   Connects standard Menu commands (`Cut`, `Copy`, `Paste`, `Select All`) to appropriate actions or responders.
*   **Error Handling:** Demonstrates basic error catching during JSON parsing and file loading, presenting user-friendly alerts via `.alert`.
*   **SF Symbols:** Uses system symbols effectively (`Image(systemName:)`) to represent JSON data types visually in the tree view.
*   **Asynchronous Operations:** Performs file loading and initial validation on a background thread (`DispatchQueue.global`) to keep the UI responsive, updating the UI back on the main thread (`DispatchQueue.main`).

---

## How It Works: From Text to Tree

1.  **Input:** The user enters or loads JSON text into the `@State var jsonText`.
2.  **Parsing Trigger:** When `jsonText` changes or the view appears, `parseJsonForViewer` is called.
3.  **Validation & Conversion:** The text is converted to `Data` (UTF-8). `JSONSerialization.jsonObject(with:options:.fragmentsAllowed)` attempts to parse the data into a Swift `Any` object (representing dictionaries, arrays, strings, numbers, booleans, or null).
4.  **Error Handling:** If parsing fails, an error message is stored in `@State var parseError`.
5.  **Tree Building:** If parsing succeeds, the recursive `createJSONItems` and `createSingleJSONItem` functions traverse the `Any` object:
    *   Dictionaries (`[String: Any]`) and Arrays (`[Any]`) are processed recursively. Keys are sorted alphabetically for objects *for display consistency*. Array order is preserved.
    *   Primitive values (String, NSNumber, NSNull) are converted into leaf `JSONItem` nodes.
    *   Each `JSONItem` stores its key/index, a display-friendly value string, semantic type, icon name, and potential children.
6.  **State Update:** The resulting array `[JSONItem]` is stored in `@State var jsonItems`.
7.  **Rendering:**
    *   If the `ContentView`'s `selectedView` is `.viewer`:
        *   The `JSONViewer` checks `parseError` and `jsonItems`.
        *   It displays `ErrorView`, `EmptyViewPlaceholder`, or the SwiftUI `List`.
        *   The `List(items, children: \.children)` uses the `JSONItem` structure to render the hierarchy.
        *   Each row is rendered by `JSONRow`, which displays the icon, key (styled differently for object keys vs. array indices), and formatted value, colored according to type.

---

## Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd <repository-folder>
    ```
2.  **Open in Xcode:** Open the `.xcodeproj` file or the containing folder if it's set up as a Swift Package.
3.  **Select Target:** Choose the macOS target (MyMacApp or similar).
4.  **Build & Run:** Press `Cmd+R` or click the Run button.
5.  **Requirements:** Requires **macOS 13.0 or later** due to the use of newer SwiftUI features like `onChange(of:initial:)`.

----

## Potential Improvements & Future Ideas

*   **Search/Filtering:** Implement search functionality within the Tree View.
*   **Syntax Highlighting:** Add syntax highlighting to the `TextEditor`.
*   **Inline Editing:** Allow editing values directly within the Tree View.
*   **Advanced Error Reporting:** Highlight the specific line/location of JSON errors in the `TextEditor`.
*   **Performance:** Optimize parsing and rendering for very large JSON files (e.g., lazy loading branches).
*   **Saving:** Add functionality to save the potentially formatted/compacted JSON text back to a file.
*   **Custom Themes:** Allow users to customize colors or choose themes.
*   **JSON Path Support:** Display or allow querying using JSON Path expressions.

----

## Contributing

Found a bug or have an improvement? Feel free to open an Issue or submit a Pull Request!

## License


- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---
