---
created: 2025-04-16 05:31:26
author: Cong Le
version: "1.0"
license(s): MIT, CC BY 4.0
copyright: Copyright (c) 2025 Cong Le. All Rights Reserved.
---



# JSON Insight for SwiftUI - A Diagrammatic Documentation - Visualized Concepts
> **Disclaimer:**
>
> This document contains my personal notes on the topic,
> compiled from publicly available documentation and various cited sources.
> The materials are intended for educational purposes, personal study, and reference.
> The content is dual-licensed:
> 1. **MIT License:** Applies to all code implementations (Swift, Mermaid, and other programming languages).
> 2. **Creative Commons Attribution 4.0 International License (CC BY 4.0):** Applies to all non-code content, including text, explanations, diagrams, and illustrations.
---

Here are several diagrams illustrating the structure, data flow, and logic of the `JSON Insight for SwiftUI` App.

## Diagram 1: Core Data Structure (`JSONItem`)

This class diagram shows the structure of the `JSONItem` struct, which is used to represent nodes in the hierarchical JSON viewer, and its relationship with the `JSONValueType` enum.

```mermaid
---
title: "Core Data Structure (`JSONItem`)"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  layout: elk
  look: handDrawn
  theme: dark
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'classDiagram': { 'htmlLabels': false},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B28',
      'primaryTextColor': '#F8B229',
      'primaryBorderColor': '#7C33',
      'secondaryColor': '#0615'
    }
  }
}%%
classDiagram
    direction LR
    class JSONItem {
        +UUID id
        +String? key
        +String value
        +JSONValueType type
        +String typeIcon
        +List~JSONItem~? children
    }
    class JSONValueType {
    <<Enumeration>>
        object
        array
        string
        number
        boolean
        null
        unknown
    }

    JSONItem "1" --o "1" JSONValueType : uses
    JSONItem "1" *-- "0..*" JSONItem : children (recursive)

```

**Explanation:**

*   `JSONItem` holds the display data for each element in the JSON tree (key, formatted value, type information, icon, and potential children).
*   `JSONValueType` defines the fundamental types according to the JSON specification.
*   The `children` property indicates the recursive nature, allowing `JSONItem` to represent nested objects and arrays.

---

## Diagram 2: Application Structure & High-Level UI Components

This diagram shows the main application object, the primary view (`ContentView`), and how it orchestrates the display of either the `TextEditor` or the `JSONViewer`.

```mermaid
---
title: "Application Structure & High-Level UI Components"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  look: handDrawn
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'graph': { 'htmlLabels': false},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B28',
      'primaryTextColor': '#000',
      'primaryBorderColor': '#7C33',
      'secondaryColor': '#0615',
      'lineColor': '#F8B229'
    }
  }
}%%
graph TD
    subgraph App_Entry["App Entry"]
    style App_Entry fill:#dd9,stroke:#333,stroke-width:1px
        App[JSONToolApp]
    end

    subgraph Main_View["Main View"]
    style Main_View fill:#dd24,stroke:#333,stroke-width:1px
        CV(ContentView)
        CV -- Manages State --> State["(@State jsonText, @State jsonItems, @State selectedView, etc.)"]
        CV -- Contains --> Toolbar(Toolbar Buttons & Picker)
        CV -- Conditional Display --> TE(TextEditor)
        CV -- Conditional Display --> JV(JSONViewer)
    end

    subgraph Viewer_Components["Viewer Components"]
    style Viewer_Components fill:#ef2,stroke:#333,stroke-width:2px
        JV -- Displays --> List(SwiftUI List)
        List -- Contains --> JR(JSONRow)
        JV -- Handles Errors --> EV(ErrorView)
        JV -- Handles Empty/Loading --> EPV(EmptyViewPlaceholder)
    end

    subgraph Data_Model["Data Model"]
    style Data_Model fill:#dd19,stroke:#333,stroke-width:1px
        JI(JSONItem)
    end

    App --> CV
    Toolbar -- Controls --> CV[selectedView]
    Toolbar -- Triggers --> Actions(Toolbar Actions e.g., formatAction)
    Actions -- Modify --> State[jsonText]
    CV[jsonText] -- Parses To --> State[jsonItems]
    JV -- Uses Data --> State[jsonItems]
    JV -- Uses Data --> JI
    JR -- Uses Data --> JI


    classDef default fill:#f9f,stroke:#333,stroke-width:2px
    classDef state fill:#D3D3D3,stroke:#333
    classDef action fill:#00FFFF,stroke:#333
    classDef viewer fill:#ADD8E6,stroke:#333
    classDef data fill:#90EE90,stroke:#333

    class App,CV,TE,JV,List,JR,EV,EPV default
    class State state
    class Actions action
    class JI data

```

**Explanation:**

*   `JSONToolApp` is the entry point.
*   `ContentView` is the main UI container, holding the `jsonText` (raw input), `jsonItems` (parsed tree data), and `selectedView` state.
*   Based on `selectedView`, `ContentView` shows either a `TextEditor` for raw input or the `JSONViewer` for the tree view.
*   `JSONViewer` uses `JSONItem` data and helper views (`JSONRow`, `ErrorView`, `EmptyViewPlaceholder`) to render the tree.
*   Toolbar actions modify `jsonText`, which in turn triggers re-parsing and updates `jsonItems`.

---

## Diagram 3: JSON Parsing Flow (`parseJsonForViewer`)

This flowchart illustrates the steps involved in parsing the raw JSON string into the `JSONItem` structure for the viewer.

```mermaid
---
title: "JSON Parsing Flow (`parseJsonForViewer`)"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  look: handDrawn
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%{
  init: {
    'flowchart': { 'htmlLabels': false},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B228',
      'primaryTextColor': '#FFF',
      'primaryBorderColor': '#7C33',
      'secondaryColor': '#0615',
      'lineColor': '#F8B229'
    }
  }
}%%
flowchart TD
    A["Start:<br/>parseJsonForViewer(jsonText)"] --> B{"Is text empty?"}
    B -- Yes --> C["jsonItems = [], parseError = nil"]
    B -- No --> D["Convert text to UTF-8 Data"]
    D --> E{"Data conversion successful?"}
    E -- No --> F["jsonItems = nil, parseError = 'UTF-8 Error'"]
    E -- Yes --> G["Attempt JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)"]
    G --> H{"Parsing successful?"}
    H -- No --> I["Catch Error"]
    I --> J["jsonItems = nil, parseError = error.localizedDescription"]
    H -- Yes --> K["Call createJSONItems(from: jsonObject)"]
    K --> L["jsonItems = result, parseError = nil"]
    M["End"]

    C --> M
    F --> M
    J --> M
    L --> M

    classDef Error_Node fill:#FF6961
    class F,J,I Error_Node

    classDef Termination_Points fill:#006400
    class A,M Termination_Points

    classDef Successful_Case fill:#A66B05
    class L Successful_Case

```

**Explanation:**

*   The function first checks for empty input.
*   It converts the string to `Data`.
*   `JSONSerialization` is used to parse the data, allowing fragments (top-level non-object/array values).
*   On success, `createJSONItems` is called to build the tree structure.
*   Errors during conversion or parsing result in setting the `parseError` state and clearing `jsonItems`.

----

## Diagram 4: Tree Building Logic (`createJSONItems` / `createSingleJSONItem`)

This flowchart outlines the recursive logic used to traverse the parsed JSON object (`Any`) and build the `[JSONItem]` array.

```mermaid
---
title: "Tree Building Logic (`createJSONItems` / `createSingleJSONItem`)"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  look: handDrawn
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'flowchart': { 'htmlLabels': false, 'curve': 'bumpY'},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B228',
      'primaryTextColor': '#FFF',
      'primaryBorderColor': '#7C33',
      'secondaryColor': '#0615',
      'lineColor': '#F8B229'
    }
  }
}%%
flowchart TD
    subgraph createJSONItems_Entry_Point["createJSONItems<br/>(Entry Point)"]
        direction LR
        IN["Input:<br/> jsonObject (Any), key (String?)"] --> T1{"jsonObject Type?"}
        T1 -- Dictionary --> D1["Sort Keys"]
        D1 --> D2["Loop: For each key/value pair"]
        D2 --> D3["Call createSingleJSONItem(value, key)"]
        D3 --> D4["Aggregate Results"]
        D4 --> OUT1["Return [JSONItem]"]
        T1 -- Array --> A1["Enumerate Array"]
        A1 --> A2["Loop:<br/>For each index/element"]
        A2 --> A3["Call createSingleJSONItem(element, String(index))"]
        A3 --> A4["Aggregate Results"]
        A4 --> OUT1
        T1 -- "Other<br/>(Fragment)" --> F1["Call createSingleJSONItem(jsonObject, key ?? 'value')"]
        F1 --> OUT1
    end

    subgraph createSingleJSONItem_Recursive_Worker["createSingleJSONItem<br/>(Recursive Worker)"]
        direction TB
        IN2["Input:<br/> value (Any), key (String)"] --> T2{"value Type?"}
        T2 -- Dictionary --> RD1["Create Children:"]
        RD1 -- Recursive Call --> IN2
        RD1 --> RD2["Create Object JSONItem<br/>(type: .object)"]
        RD2 --> RD3["Set Children & Value String"]
        RD3 --> OUT2["Return [Object Item]"]

        T2 -- Array --> RA1["Create Children:"]
        RA1 -- Recursive Call --> IN2
        RA1 --> RA2["Create Array JSONItem<br/>(type: .array)"]
        RA2 --> RA3["Set Children & Value String"]
        RA3 --> OUT2

        T2 -- String --> S1["Create String JSONItem<br/>(type: .string, value: '\'\(value)\'')"]
        S1 --> OUT2

        T2 -- NSNumber --> N1{"Is Boolean?<br/>(isBoolean())"}
        N1 -- Yes --> B1["Create Boolean JSONItem<br/>(type: .boolean, value: 'true'/'false')"]
        B1 --> OUT2
        N1 -- "No<br/>(Number)" --> N2[Format number]
        N2 --> N3["Create Number JSONItem<br/>(type: .number)"]
        N3 --> OUT2

        T2 -- NSNull --> L1["Create Null JSONItem<br/>(type: .null, value: 'null')"]
        L1 --> OUT2

        T2 -- Other/Unknown --> U1["Create Unknown JSONItem<br/>(type: .unknown)"]
        U1 --> OUT2
    end

    D3 --> IN2
    A3 --> IN2
    F1 --> IN2

    classDef entry fill:#e6f2ff,stroke:#0066cc
    classDef worker fill:#fff2e6,stroke:#cc6600
    classDef recursive fill:#ccffcc,stroke:#006600
    class D3,A3,F1,RD1,RA1 recursive
    class IN,T1,D1,D2,D4,A1,A2,A4,F1,OUT1 entry
    class IN2,T2,RD2,RD3,RA2,RA3,S1,N1,N2,N3,B1,L1,U1,OUT2 worker

```

**Explanation:**

*   `createJSONItems` determines if the root is an object, array, or fragment and delegates the creation of individual items to `createSingleJSONItem`. It sorts dictionary keys for consistent display.
*   `createSingleJSONItem` is the core recursive function:
    *   It checks the type of the input `value`.
    *   For Dictionaries and Arrays, it *recursively calls itself* to build the children list first, then creates the parent `JSONItem`.
    *   For primitive types (String, Number, Boolean, Null), it creates a leaf `JSONItem` with the appropriate type, formatted value string, and icon name.
    *   It handles unknown types defensively.
    *   Crucially, it returns `[JSONItem]?` to consistently handle both single items (like fragments) and collections returned from recursive calls.

----

## Diagram 5: ContentView UI State Management

This diagram shows how the `ContentView` switches between Text and Viewer modes and how actions trigger updates.

```mermaid
---
title: "ContentView UI State Management"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  look: handDrawn
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'bumpY'},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B228',
      'primaryTextColor': '#000',
      'primaryBorderColor': '#7C3',
      'secondaryColor': '#0611',
      'lineColor': '#F8B229'
    }
  }
}%%
graph TD
    A("Start / View Appears") --> B("Initial parseJsonForViewer")

    subgraph State_Rendering_Loop["State & Rendering Loop"]
        C{"selectedView State?"} -- ".text" --> D["Display TextEditor"]
        C -- ".viewer" --> E{"Parse error?"}
        E -- Yes --> F["JSONViewer displays ErrorView"]
        E -- No --> G{"jsonItems empty?"}
        G -- Yes --> H["JSONViewer displays EmptyPlaceholder"]
        G -- No --> I["JSONViewer displays List of JSONRows"]
    end

    subgraph User_Interactions["User Interactions"]
        Picker["User changes View Mode Picker"] --> UpdateSV("Update @State selectedView")
        Buttons["User clicks Toolbar Button<br/>(e.g., Format, Load)"] --> Action("Call corresponding Action Func")
        Action -- Modifies --> TextState("@State jsonText")
        TextEditorInput["User types in TextEditor"] --> TextState
    end

    subgraph Update_Triggers["Update Triggers"]
        B --> C
        UpdateSV --> C
        TextState -- Triggers onChange --> Parse("Call parseJsonForViewer")
        Parse --> ItemsState("@State jsonItems / @State parseError")
        ItemsState --> C
    end

    classDef state fill:#FFFFE0,stroke:#333
    classDef trigger fill:#ADD8E6,stroke:#333
    classDef action fill:#8EB28E,stroke:#006600

    class C,E,G,TextState,ItemsState,selectedView state
    class Picker,Buttons,TextEditorInput action
    class B,Parse,UpdateSV trigger

```

**Explanation:**

*   On appear and whenever `jsonText` changes, `parseJsonForViewer` is called.
*   The `selectedView` state dictates whether `TextEditor` or `JSONViewer` is shown.
*   `JSONViewer` internally decides whether to show an error, an empty placeholder, or the list based on the `parseError` and `jsonItems` state.
*   User interactions like changing the picker, clicking buttons, or typing in the editor update the relevant state (`selectedView` or `jsonText`), which then triggers re-parsing or re-rendering loops.


-----

## Diagram 6: `JSONViewer` Internal Rendering Logic

This flowchart describes how the `JSONViewer` decides what to display based on its input `items` and `error`.

```mermaid
---
title: "`JSONViewer` Internal Rendering Logic"
author: "Cong Le"
version: "1.0"
license(s): "MIT, CC BY 4.0"
copyright: "Copyright (c) 2025 Cong Le. All Rights Reserved."
config:
  look: handDrawn
  theme: base
---
%%%%%%%% Mermaid version v11.4.1-b.14
%%%%%%%% Toggle theme value to `base` to activate the initilization below for the customized theme version.
%%%%%%%% Available curve styles include the following keywords:
%% basis, bumpX, bumpY, cardinal, catmullRom, linear, monotoneX, monotoneY, natural, step, stepAfter, stepBefore.
%%{
  init: {
    'graph': { 'htmlLabels': false, 'curve': 'bumpY'},
    'fontFamily': 'Monospace',
    'themeVariables': {
      'primaryColor': '#B228',
      'primaryTextColor': '#000',
      'primaryBorderColor': '#7C3',
      'secondaryColor': '#0611',
      'lineColor': '#F8B229'
    }
  }
}%%
graph TD
    A("Start / View Appears") --> B("Initial parseJsonForViewer")

    subgraph State_Rendering_Loop["State & Rendering Loop"]
    style State_Rendering_Loop fill:#eed9,stroke:#333,stroke-width:2px
        C{"selectedView State?"} -- ".text" --> D["Display TextEditor"]
        C -- ".viewer" --> E{"Parse error?"}
        E -- Yes --> F["JSONViewer displays ErrorView"]
        E -- No --> G{"jsonItems empty?"}
        G -- Yes --> H["JSONViewer displays EmptyPlaceholder"]
        G -- No --> I["JSONViewer displays List of JSONRows"]
    end

    subgraph User_Interactions["User Interactions"]
    style User_Interactions fill:#eed991,stroke:#333,stroke-width:2px
        Picker["User changes View Mode Picker"] --> UpdateSV("Update @State selectedView")
        Buttons["User clicks Toolbar Button<br/>(e.g., Format, Load)"] --> Action("Call corresponding Action Func")
        Action -- Modifies --> TextState("@State jsonText")
        TextEditorInput["User types in TextEditor"] --> TextState
    end

    subgraph Update_Triggers["Update Triggers"]
    style Update_Triggers fill:#ed9,stroke:#333,stroke-width:2px
        B --> C
        UpdateSV --> C
        TextState -- Triggers onChange --> Parse("Call parseJsonForViewer")
        Parse --> ItemsState("@State jsonItems / @State parseError")
        ItemsState --> C
    end

    classDef state fill:#FFFFE0,stroke:#333
    classDef trigger fill:#ADD8E6,stroke:#333
    classDef action fill:#8EB28E,stroke:#006600

    class C,E,G,TextState,ItemsState,selectedView state
    class Picker,Buttons,TextEditorInput action
    class B,Parse,UpdateSV trigger

```

**Explanation:**

*   The `JSONViewer` prioritizes showing an error if one exists.
*   If there's no error, it checks if `items` are available (parsed). If not, it shows a "Parsing..." message.
*   If items are available but empty, it shows an "Empty JSON" message.
*   Otherwise, it renders the SwiftUI `List`, configured to handle the hierarchical `children` relationship of `JSONItem`, using `JSONRow` to render each individual item.



---
**Licenses:**

- **MIT License:**  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) - Full text in [LICENSE](LICENSE) file.
- **Creative Commons Attribution 4.0 International:** [![License: CC BY 4.0](https://licensebuttons.net/l/by/4.0/88x31.png)](LICENSE-CC-BY) - Legal details in [LICENSE-CC-BY](LICENSE-CC-BY) and at [Creative Commons official site](http://creativecommons.org/licenses/by/4.0/).

---