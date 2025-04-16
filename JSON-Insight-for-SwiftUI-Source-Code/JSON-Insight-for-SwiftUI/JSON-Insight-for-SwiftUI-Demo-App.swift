//
//  JSON-Insight-for-SwiftUI-Demo-App.swift
//  JSON-Insight-for-SwiftUI
//
//  Created by Cong Le on 4/16/25.
//

import SwiftUI
import UniformTypeIdentifiers // For UTType.json

// MARK: - Data Structure for Tree View (JSONItem)
/// Represents a single node in the JSON tree structure for display in the viewer.
/// Conforms to Identifiable for use with SwiftUI's List.
struct JSONItem: Identifiable {
    let id = UUID() // Unique ID for SwiftUI List rendering.
    let key: String? // Key name (for objects) or index as String (for arrays). Nil for root fragment.
    let value: String // A user-friendly string representation of the value for display.
    let type: JSONValueType // Semantic type according to JSON specification.
    let typeIcon: String // SF Symbol name representing the type.
    var children: [JSONItem]? = nil // Child items for Objects and Arrays.

    /// Enum representing the 7 fundamental JSON value types.
    enum JSONValueType {
        case object, array, string, number, boolean, null, unknown
    }
}

// MARK: - Main Application Structure (No changes needed here)
@main
struct JSONToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .pasteboard) {
                 // Pasteboard commands remain the same...
                 Button("Cut") { if copySelectionToPasteboard() { print("Cut action needs deeper TextEditor integration for deletion") } }
                     .keyboardShortcut("x", modifiers: .command)
                 Button("Copy") { _ = copySelectionToPasteboard() }
                     .keyboardShortcut("c", modifiers: .command)
                 Button("Paste") { pasteFromPasteboard() }
                     .keyboardShortcut("v", modifiers: .command)
                 Button("Select All") {
                     DispatchQueue.main.async { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                 }
                 .keyboardShortcut("a", modifiers: .command)
            }
         }
    }

    // Pasteboard helpers remain the same...
    private func copySelectionToPasteboard() -> Bool { /* ... */
        guard let focusedView = NSApp.keyWindow?.firstResponder, focusedView.responds(to: #selector(NSText.copy(_:))) else { return false }
        focusedView.perform(#selector(NSText.copy(_:)), with: nil)
        return true
    }
    private func pasteFromPasteboard() { /* ... */
        guard let focusedView = NSApp.keyWindow?.firstResponder, focusedView.responds(to: #selector(NSText.paste(_:))) else { return }
        focusedView.perform(#selector(NSText.paste(_:)), with: nil)
    }
}

// MARK: - Main View Structure (ContentView - Updated)
struct ContentView: View {
    @State private var selectedView: ViewMode = .text
    // Default JSON for demonstration
    @State private var jsonText: String = """
    {
      "specification": "ECMA-404",
      "name": "Example JSON",
      "version": 1.0,
      "enabled": true,
      "items": [
        {"id": 1, "value": "apple", "tags": ["fruit", "red"]},
        {"id": 2, "value": "banana", "tags": ["fruit", "yellow", null]},
        null,
        [10, 20.5, -30e-1, 40],
        {},
        "string item",
        false
      ],
      "settings": {
        "theme": "dark",
        "zoom_level": 1.25,
        "notifications": null,
        "features": {
            "featureA": true,
            "featureB": false
        }
      },
      "emptyObject": {},
      "emptyArray": [],
      "justNull": null
    }
    """
    @State private var jsonItems: [JSONItem]? = nil // State for parsed tree items
    @State private var parseError: String? = nil // State for viewer parse errors

    // State for general alerts
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // View selection modes
    enum ViewMode: String, CaseIterable, Identifiable {
        case viewer = "Viewer"
        case text = "Text"
        var id: String { self.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // --- Content Area ---
            if selectedView == .text {
                // Standard TextEditor view
                ScrollView {
                    TextEditor(text: $jsonText)
                        .font(.monospaced(.body)())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(5)
                        .background(Color(nsColor: .textBackgroundColor))
                        .border(Color.gray.opacity(0.3), width: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedView == .viewer {
                // Integrated JSONViewer
                JSONViewer(items: jsonItems, error: parseError)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor))
                    .border(Color.gray.opacity(0.3), width: 1)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            // --- Toolbar ---
            ToolbarItemGroup(placement: .navigation) {
                Picker("View Mode", selection: $selectedView) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .help("Switch between Text Editor and structured Viewer")
            }
            // Action buttons remain the same...
            ToolbarItemGroup(placement: .primaryAction) {
                /* ... buttons ... */
                Button { pasteAction() } label: { Label("Paste", systemImage: "doc.on.clipboard") }.help("Paste")
                Button { copyAction() } label: { Label("Copy", systemImage: "doc.on.doc") }.help("Copy")
                Button { formatAction() } label: { Label("Format", systemImage: "text.alignleft") }.help("Format")
                Button { removeWhitespaceAction() } label: { Label("Compact", systemImage: "text.compress") }.help("Compact")
                Spacer()
                Button(role: .destructive) { clearAction() } label: { Label("Clear", systemImage: "xmark.circle") }.help("Clear")
                Button { loadJsonDataAction() } label: { Label("Load JSON", systemImage: "doc.badge.plus") }.help("Load JSON")
            }
        }
        .alert("Error", isPresented: $showingAlert, actions: {
             Button("OK", role: .cancel) {}
         }, message: {
             Text(alertMessage)
         })
        // --- Trigger parsing when text changes or view appears ---
        .onChange(of: jsonText) { // Using new signature for macOS 13+
            parseJsonForViewer(jsonText)
        }
        .onAppear {
             parseJsonForViewer(jsonText) // Parse initial text
        }
    }

    // MARK: - Parsing Logic for Viewer
    /// Parses the input JSON string and updates the state for the JSONViewer.
    private func parseJsonForViewer(_ text: String) {
        // Basic check for empty input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.jsonItems = []
            self.parseError = nil // Empty is not an error
            return
        }

        // Convert string to data for JSONSerialization
        guard let data = text.data(using: .utf8) else {
            self.jsonItems = nil
            self.parseError = "Error: Could not encode text to UTF-8 data."
            return
        }

        // Attempt to parse using JSONSerialization
        do {
            // .fragmentsAllowed permits top-level values that aren't arrays or objects (e.g., "string", 123, true)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            self.jsonItems = createJSONItems(from: jsonObject) // Build the tree structure
            self.parseError = nil // Clear any previous errors
        } catch {
            print("JSON parsing error for viewer: \(error)")
            self.jsonItems = nil // Clear items on error
            self.parseError = "Invalid JSON: \(error.localizedDescription)" // Provide error message
        }
    }

   /// Recursively creates the array of JSONItem nodes from a parsed JSON object (Any).
   /// This is the entry point for converting the parsed data structure to our display structure.
    private func createJSONItems(from jsonObject: Any, key: String? = nil) -> [JSONItem]? {
        // Handle the root case: If it's an object or array, create items for its contents.
        // If it's a simple value (string, number, bool, null), wrap it in a single-item array.
        if let dictionary = jsonObject as? [String: Any] {
            // Process Object: Create items for each key-value pair.
            // Note: JSON spec defines objects as UNORDERED. We sort keys *for display consistency* only.
            return dictionary.sorted(by: { $0.key < $1.key }) // Sort keys alphabetically for viewer
                           .compactMap { createSingleJSONItem(from: $0.value, key: $0.key) } // Create item for each pair
                           .flatMap { $0 } // Since createSingleJSONItem returns [JSONItem]?

        } else if let array = jsonObject as? [Any] {
            // Process Array: Create items for each element using its index as the "key".
            // JSON spec defines arrays as ORDERED. We preserve this order using enumerated().
            return array.enumerated()
                        .compactMap { createSingleJSONItem(from: $0.element, key: String($0.offset)) } // Use index as key
                        .flatMap { $0 }

        } else {
            // Process non-container root (fragment): String, Number, Boolean, Null
            // Create a single item array to represent this root value.
            if let singleItem = createSingleJSONItem(from: jsonObject, key: key ?? "value") {
                return singleItem // It now correctly returns [JSONItem] directly
            } else {
                // Should not happen if fragmentsAllowed parsed it, but handle defensively.
                print("Warning: Failed to create item for root fragment.")
                return nil
            }
        }
    }

    /// Creates a single JSONItem or an array containing one JSONItem based on the value type.
    /// Handles recursion for nested objects and arrays.
    /// Returns an array `[JSONItem]` to handle fragments at the root more consistently.
    private func createSingleJSONItem(from value: Any, key: String) -> [JSONItem]? {

        if let dictionary = value as? [String: Any] {
            // Create an item representing a JSON Object {}.
            let children = dictionary.sorted(by: { $0.key < $1.key }) // Sort for display
                                     .compactMap { createSingleJSONItem(from: $0.value, key: $0.key) }
                                     .flatMap { $0 }
            let valueString = dictionary.isEmpty ? "{}" : "{\(children.count) item\(children.count == 1 ? "" : "s")}"
            let item = JSONItem(key: key, value: valueString, type: .object, typeIcon: "folder", children: children.isEmpty ? nil : children)
            return [item]

        } else if let array = value as? [Any] {
            // Create an item representing a JSON Array [].
            let children = array.enumerated() // Preserve order
                              .compactMap { createSingleJSONItem(from: $0.element, key: String($0.offset)) }
                              .flatMap { $0 }
            let valueString = array.isEmpty ? "[]" : "[\(children.count) item\(children.count == 1 ? "" : "s")]"
            let item = JSONItem(key: key, value: valueString, type: .array, typeIcon: "list.bullet", children: children.isEmpty ? nil : children)
            return [item]

        } else if let string = value as? String {
            // Create an item for a JSON String. Display with quotes.
            let item = JSONItem(key: key, value: "\"\(string)\"", type: .string, typeIcon: "textformat.abc")
            return [item]

        } else if let number = value as? NSNumber {
            // Create an item for a JSON Number or Boolean.
            if number.isBoolean() {
                 // Handle Boolean (true/false)
                 let boolValue = number.boolValue
                 let item = JSONItem(key: key, value: boolValue ? "true" : "false", type: .boolean, typeIcon: boolValue ? "checkmark.circle.fill" : "xmark.circle.fill") // Alt: "check.mark"/"x.mark"
                 return [item]
             } else {
                 // Handle Number (Integer or Floating Point)
                 // JSON spec doesn't distinguish int/float, just "number".
                 let formatter = NumberFormatter()
                 formatter.numberStyle = .decimal // Use standard decimal format
                 formatter.maximumFractionDigits = 15 // Avoid excessive precision loss display
                 formatter.usesGroupingSeparator = false // Avoid locale-specific separators like commas
                 let numberString = formatter.string(from: number) ?? "\(number)" // Fallback
                 let item = JSONItem(key: key, value: numberString, type: .number, typeIcon: "number")
                 return [item]
             }

        } else if value is NSNull {
            // Create an item for JSON Null.
            let item = JSONItem(key: key, value: "null", type: .null, typeIcon: "circle.slash") // Alt: "nosign"
            return [item]

        } else {
             // Should ideally not happen with standard JSON.
             print("Unhandled JSON type encountered for key '\(key)': \(type(of: value))")
             let item = JSONItem(key:key, value: "Unknown Type", type: .unknown, typeIcon: "questionmark.diamond")
             return [item]
        }
    }

    // MARK: - Action Implementations (Mostly unchanged, ensure format/compact use correct options)

    func pasteAction() { /* ... */
        NSPasteboard.general.string(forType: .string).map { jsonText = $0 } ?? showAlert(message: "Clipboard does not contain text.")
    }
    func copyAction() { /* ... */
        NSPasteboard.general.clearContents()
        if !NSPasteboard.general.setString(jsonText, forType: .string) { showAlert(message: "Failed to copy text to clipboard.") }
    }
    func formatAction() { /* ... */
        guard let data = jsonText.data(using: .utf8) else { showAlert(message: "Invalid UTF-8 text."); return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) // Use options for readability
            if let formattedString = String(data: prettyData, encoding: .utf8) { jsonText = formattedString }
            else { showAlert(message: "Failed to decode formatted JSON.") }
        } catch { showAlert(message: "Invalid JSON. Cannot format.\n\n\(error.localizedDescription)") }
    }
    func removeWhitespaceAction() { /* ... */
        guard let data = jsonText.data(using: .utf8) else { showAlert(message: "Invalid UTF-8 text."); return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let compactData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.withoutEscapingSlashes]) // Minimal options for compactness
            if let compactString = String(data: compactData, encoding: .utf8) { jsonText = compactString }
            else { showAlert(message: "Failed to decode compacted JSON.") }
        } catch { showAlert(message: "Invalid JSON. Cannot compact.\n\n\(error.localizedDescription)") }
    }
    func clearAction() { /* ... */ jsonText = "" }
    func loadJsonDataAction() { /* ... */
        let openPanel = NSOpenPanel() /* ... setup ... */
        openPanel.canChooseFiles = true; openPanel.canChooseDirectories = false; openPanel.allowsMultipleSelection = false; openPanel.allowedContentTypes = [UTType.json] // Use correct type
        openPanel.begin { [self] response in /* ... async loading ... */
            if response == .OK, let url = openPanel.url {
                 DispatchQueue.global(qos: .userInitiated).async {
                     do {
                         let loadedText = try String(contentsOf: url, encoding: .utf8)
                         // Quick validation check on background thread
                         _ = try JSONSerialization.jsonObject(with: loadedText.data(using: .utf8)!, options: .fragmentsAllowed)
                         DispatchQueue.main.async { self.jsonText = loadedText } // Update UI on main thread
                     } catch {
                          print("Error loading file: \(error)")
                          DispatchQueue.main.async { self.showAlert(message: "Failed to load/parse file: \(url.lastPathComponent)\n\n\(error.localizedDescription)") }
                     }
                 }
             }
         }
    }

    // MARK: - Helper Methods
    private func showAlert(message: String) { /* ... */ alertMessage = message; showingAlert = true }
}

// MARK: - JSON Viewer View (JSONViewer - Updated)
/// A SwiftUI View that displays parsed JSON data in a hierarchical list.
struct JSONViewer: View {
    let items: [JSONItem]? // Root level items
    let error: String?     // Error message if parsing failed

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = error {
                // Display error prominently
                 ErrorView(message: error)
            } else if let items = items {
                if items.isEmpty {
                    // Handle empty JSON or cleared state
                    EmptyViewPlaceholder(text: "Empty JSON")
                } else {
                    // Display the hierarchical list
                    List(items, children: \.children) { item in
                        JSONRow(item: item)
                    }
                    .listStyle(.inset) // Or .plain based on preference
                    .background(Color(nsColor: .textBackgroundColor)) // Ensure background consistency
                }
            } else {
                // Loading or initial state
                EmptyViewPlaceholder(text: "Parsing JSON...")
            }
        }
    }
}

// MARK: - Helper Views for JSONViewer

/// Displays a single row in the JSONViewer list.
struct JSONRow: View {
    let item: JSONItem

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: item.typeIcon)
                .foregroundColor(iconColor(for: item.type))
                .frame(width: 20, alignment: .center) // Align icons

            // Display Key (if it exists)
            if let key = item.key {
                // Distinguish between Array Index and Object Key visually
                if item.type == .object || item.type == .array || item.type == .string || item.type == .number || item.type == .boolean || item.type == .null {
                    // Check if parent was likely an array by seeing if key is numeric
                    // This is heuristic; parsing context would be more robust but complex here.
                    if Int(key) != nil && (parentTypeApproximation(item:item) == .array)  {
                         Text("[\(key)]:") // Array index style
                             .foregroundColor(.purple.opacity(0.8))
                             .font(.monospaced(.body)())
                             .fontWeight(.medium)
                     } else {
                         Text("\(key):") // Object key style (always string according to spec)
                             .foregroundColor(.blue) // Consistent color for keys
                             .font(.monospaced(.body)())
                             .fontWeight(.medium)
                     }
                 }
                 // else: No key for root fragments (should be handled by how `createJSONItems` calls this)
            }

            // Display Value (formatted string)
            Text(item.value)
               .font(.monospaced(.body)())
               .foregroundColor(valueColor(for: item.type))
               .lineLimit(1) // Keep rows compact
               .truncationMode(.tail)

            Spacer() // Push content to the left
        }
        // Slightly indent leaf nodes (those without children) for visual structure
        .padding(.leading, (item.children?.isEmpty ?? true) ? 5 : 0)
    }

    // Heuristic to guess parent type for styling index vs key
    // A better approach would pass parent type down during parsing.
    private func parentTypeApproximation(item: JSONItem) -> JSONItem.JSONValueType {
        // If the key is an integer, it's likely from an array during enumeration.
         if let key = item.key, Int(key) != nil {
             return .array
         }
         // Otherwise, assume it's a key in an object.
         return .object
    }

    // Helper to determine icon color based on semantic type
    private func iconColor(for type: JSONItem.JSONValueType) -> Color {
        switch type {
        case .object: return .gray
        case .array: return .gray
        case .string: return .red
        case .number: return .green
        case .boolean: return .orange
        case .null: return .secondary          // More subdued for null
        case .unknown: return .primary
        }
    }

     // Helper to determine text color for the value based on semantic type
    private func valueColor(for type: JSONItem.JSONValueType) -> Color {
        switch type {
        case .object: return .primary       // Use primary for container summary text
        case .array: return .primary
        case .string: return .red
        case .number: return .green
        case .boolean: return .orange
        case .null: return .secondary.opacity(0.8) // Match icon color
        case .unknown: return .primary
        }
    }
}

/// Displays a centered message for error or empty states.
struct ErrorView: View {
    let message: String

    var body: some View {
         VStack {
             Spacer()
             HStack {
                  Spacer()
                 Image(systemName: "exclamationmark.triangle.fill")
                     .foregroundColor(.orange)
                     .font(.title)
                 Text("Error Parsing JSON")
                      .font(.headline)
                  Spacer()
             }
             Text(message)
                   .font(.caption)
                   .foregroundColor(.gray)
                   .multilineTextAlignment(.center)
                   .padding()
             Spacer()
        }
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .background(Color(nsColor: .textBackgroundColor))
    }
}

/// Displays a centered placeholder text.
struct EmptyViewPlaceholder: View {
    let text: String

    var body: some View {
         Text(text)
             .foregroundColor(.gray)
             .frame(maxWidth: .infinity, maxHeight: .infinity)
             .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Helper Extension for NSNumber
extension NSNumber {
    /// Checks if an NSNumber represents a boolean value (true/false).
    /// JSONSerialization maps true/false to NSNumber(1)/NSNumber(0).
    fileprivate func isBoolean() -> Bool {
        // Comparing the Obj-C type is the most reliable way.
        CFGetTypeID(self) == CFBooleanGetTypeID()
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .frame(width: 800, height: 700) // Adjust size for better preview
}
