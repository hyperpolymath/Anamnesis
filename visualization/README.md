# Visualization Component (ReScript)

Type-safe, functional visualization layer for exploring conversation graphs, artifact lifecycles, and multi-project categorization.

## Purpose

- Visualize conversation graphs (messages, artifacts, relationships)
- Display artifact lifecycle timelines
- Show fuzzy multi-project categorization
- Interactive search, filter, and exploration
- Communicate with Elixir backend via HTTP API

## Technology Stack

- **ReScript** 11+ - Type-safe functional language compiling to JavaScript
- **React** 18+ - UI component library
- **rescript-react** - Official React bindings
- **Reagraph** - WebGL graph visualization (custom bindings)
- **rescript-recharts** - Timeline/chart visualization
- **Vite** - Build tool and dev server

## Directory Structure

```
visualization/
├── src/
│   ├── Anamnesis.res              # Root module
│   ├── bindings/
│   │   ├── Reagraph.res           # Graph visualization bindings
│   │   ├── Recharts.res           # Re-export rescript-recharts
│   │   └── SvarGantt.res          # Timeline/Gantt bindings
│   ├── components/
│   │   ├── ConversationGraph.res  # Main graph visualization
│   │   ├── ArtifactTimeline.res   # Lifecycle Gantt chart
│   │   ├── ProjectCategories.res  # Fuzzy membership viz
│   │   ├── SearchFilter.res       # Interactive filtering
│   │   ├── EpisodeRecall.res      # Memory query interface
│   │   └── App.res                # Root component
│   ├── state/
│   │   ├── AppState.res           # Global state (useReducer)
│   │   └── Api.res                # Elixir backend API
│   ├── types/
│   │   ├── Domain.res             # Core domain types
│   │   ├── GraphData.res          # Graph structures
│   │   └── ApiTypes.res           # API request/response types
│   ├── transforms/
│   │   ├── SparqlToGraph.res      # SPARQL results → graph
│   │   └── ColorMixing.res        # Fuzzy category colors
│   └── Index.res                  # Entry point
├── public/
│   ├── index.html
│   └── assets/
├── bsconfig.json                  # ReScript compiler config
├── package.json
├── vite.config.js
└── README.md                      # This file
```

## Key Concepts

### Type-Safe Domain Modeling

```rescript
// types/Domain.res

// Phantom types prevent mixing IDs
type messageId = MessageId(string)
type artifactId = ArtifactId(string)
type conversationId = ConversationId(string)

// Node types (discriminated union)
type nodeId =
  | MessageNode(messageId)
  | ArtifactNode(artifactId)

// Edge types
type edgeType =
  | Contains
  | References
  | CreatedIn
  | ModifiedIn
  | Evaluates

// Fuzzy project membership
type projectMembership = {
  projectId: string,
  strength: float,  // 0.0 to 1.0
}

// Node structure
type node = {
  id: nodeId,
  label: string,
  timestamp: Js.Date.t,
  speaker: option<string>,
  projects: array<projectMembership>,
  content: option<string>,
}

// Edge structure
type edge = {
  source: nodeId,
  target: nodeId,
  edgeType: edgeType,
}

// Graph
type graph = {
  nodes: array<node>,
  edges: array<edge>,
}
```

### Reagraph Bindings

```rescript
// bindings/Reagraph.res

module GraphCanvas = {
  type props = {
    nodes: array<node>,
    edges: array<edge>,
    draggable: bool,
    onNodeClick: option<node => unit>,
  }

  @module("reagraph") @react.component
  external make: (
    ~nodes: array<node>,
    ~edges: array<edge>,
    ~draggable: bool=?,
    ~onNodeClick: node => unit=?,
  ) => React.element = "GraphCanvas"
}

type reagraphNode = {
  id: string,
  label: string,
  fill: option<string>,
  size: option<float>,
}

type reagraphEdge = {
  id: string,
  source: string,
  target: string,
  label: option<string>,
}

// Convert domain model to Reagraph format
let toReagraphNode = (node: Domain.node): reagraphNode => {
  {
    id: Domain.nodeIdToString(node.id),
    label: node.label,
    fill: Some(ColorMixing.mixColors(node.projects)),
    size: Some(10.0),
  }
}

let toReagraphEdge = (edge: Domain.edge): reagraphEdge => {
  {
    id: `${Domain.nodeIdToString(edge.source)}-${Domain.nodeIdToString(edge.target)}`,
    source: Domain.nodeIdToString(edge.source),
    target: Domain.nodeIdToString(edge.target),
    label: Some(Domain.edgeTypeToString(edge.edgeType)),
  }
}
```

### Color Mixing (Fuzzy Categories)

```rescript
// transforms/ColorMixing.res

type rgb = {r: int, g: int, b: int}

let projectColors = Map.String.fromArray([
  ("anamnesis", {r: 72, g: 187, b: 120}),           // Green
  ("rescript-evangeliser", {r: 230, g: 74, b: 25}), // Orange
  ("zotero-nsai", {r: 52, g: 152, b: 219}),         // Blue
])

let mixColors = (memberships: array<Domain.projectMembership>): string => {
  let totalWeight = memberships
    ->Array.reduce(0.0, (acc, m) => acc +. m.strength)

  if totalWeight == 0.0 {
    "#999999"  // Gray for uncategorized
  } else {
    let mixed = memberships->Array.reduce(
      {r: 0, g: 0, b: 0},
      (acc, {projectId, strength}) => {
        switch projectColors->Map.String.get(projectId) {
        | None => acc
        | Some(color) => {
            r: acc.r + Float.toInt(Int.toFloat(color.r) *. strength),
            g: acc.g + Float.toInt(Int.toFloat(color.g) *. strength),
            b: acc.b + Float.toInt(Int.toFloat(color.b) *. strength),
          }
        }
      }
    )

    let normalize = (v) => min(255, Float.toInt(
      Int.toFloat(v) /. totalWeight
    ))

    `rgb(${Int.toString(normalize(mixed.r))}, ${Int.toString(normalize(mixed.g))}, ${Int.toString(normalize(mixed.b))})`
  }
}
```

### State Management

```rescript
// state/AppState.res

type state = {
  graph: option<Domain.graph>,
  selectedNode: option<Domain.nodeId>,
  filter: filterState,
  loading: bool,
  error: option<string>,
}

and filterState = {
  searchText: string,
  projectFilter: array<string>,
  dateRange: option<(Js.Date.t, Js.Date.t)>,
  speakers: array<string>,
}

type action =
  | LoadGraph(Domain.graph)
  | SelectNode(Domain.nodeId)
  | UpdateFilter(filterState)
  | SetLoading(bool)
  | SetError(string)
  | ClearError

let reducer = (state: state, action: action): state => {
  switch action {
  | LoadGraph(graph) => {...state, graph: Some(graph), loading: false}
  | SelectNode(nodeId) => {...state, selectedNode: Some(nodeId)}
  | UpdateFilter(filter) => {...state, filter}
  | SetLoading(loading) => {...state, loading}
  | SetError(err) => {...state, error: Some(err), loading: false}
  | ClearError => {...state, error: None}
  }
}

let initialState = {
  graph: None,
  selectedNode: None,
  filter: {
    searchText: "",
    projectFilter: [],
    dateRange: None,
    speakers: [],
  },
  loading: false,
  error: None,
}
```

### API Client

```rescript
// state/Api.res

type apiError =
  | NetworkError(string)
  | DecodeError(string)
  | ServerError(int, string)

let fetchGraph = async (conversationId: string): result<Domain.graph, apiError> => {
  try {
    let response = await Fetch.fetch(
      `http://localhost:4000/api/conversations/${conversationId}/graph`
    )

    if response->Fetch.Response.ok {
      let json = await response->Fetch.Response.json
      switch json->Decode.graph {
      | Ok(graph) => Ok(graph)
      | Error(err) => Error(DecodeError(err))
      }
    } else {
      Error(ServerError(
        response->Fetch.Response.status,
        await response->Fetch.Response.text
      ))
    }
  } catch {
  | Js.Exn.Error(e) =>
    switch Js.Exn.message(e) {
    | Some(msg) => Error(NetworkError(msg))
    | None => Error(NetworkError("Unknown network error"))
    }
  }
}

let sparqlQuery = async (query: string): result<Js.Json.t, apiError> => {
  try {
    let response = await Fetch.fetch(
      "http://localhost:4000/api/query",
      {
        method: #POST,
        headers: {"Content-Type": "application/json"},
        body: Js.Json.stringifyAny({"sparql": query})->Option.getExn,
      }
    )

    if response->Fetch.Response.ok {
      Ok(await response->Fetch.Response.json)
    } else {
      Error(ServerError(
        response->Fetch.Response.status,
        await response->Fetch.Response.text
      ))
    }
  } catch {
  | Js.Exn.Error(e) =>
    Error(NetworkError(Js.Exn.message(e)->Option.getWithDefault("Unknown error")))
  }
}
```

## Building

### Prerequisites

```bash
# Install Node.js 18+
nvm install 18
nvm use 18

# OR using package manager
brew install node  # macOS
```

### Install Dependencies

```bash
cd visualization
npm install
```

### Package List

```json
{
  "dependencies": {
    "@rescript/core": "^1.0.0",
    "@rescript/react": "^0.12.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "reagraph": "^4.0.0",
    "@minnozz/rescript-recharts": "^1.0.0"
  },
  "devDependencies": {
    "rescript": "^11.0.0",
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.0.0"
  }
}
```

### ReScript Config

```json
// bsconfig.json
{
  "name": "anamnesis-visualization",
  "version": "0.1.0",
  "sources": [
    {
      "dir": "src",
      "subdirs": true
    }
  ],
  "package-specs": [
    {
      "module": "es6",
      "in-source": true
    }
  ],
  "suffix": ".bs.js",
  "bs-dependencies": [
    "@rescript/core",
    "@rescript/react"
  ],
  "reason": {
    "react-jsx": 4
  },
  "warnings": {
    "error": "+101+8"
  }
}
```

### Build & Run

```bash
# Development mode (watch + hot reload)
npm run dev

# Production build
npm run build

# Type check
npm run res:build
```

## Usage

### Main App Component

```rescript
// components/App.res

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(AppState.reducer, AppState.initialState)

  React.useEffect0(() => {
    let loadInitialData = async () => {
      dispatch(SetLoading(true))
      switch await Api.fetchGraph("latest") {
      | Ok(graph) => dispatch(LoadGraph(graph))
      | Error(err) => dispatch(SetError(Api.errorToString(err)))
      }
    }
    loadInitialData()->ignore
    None
  })

  <div className="app">
    <header>
      <h1>{"Anamnesis Conversation Explorer"->React.string}</h1>
      <SearchFilter filter={state.filter} onChange={f => dispatch(UpdateFilter(f))} />
    </header>

    <main>
      {switch (state.loading, state.graph, state.error) {
      | (true, _, _) => <div>{"Loading..."->React.string}</div>
      | (_, _, Some(err)) => <div className="error">{err->React.string}</div>
      | (_, Some(graph), _) =>
        <div className="visualization-grid">
          <ConversationGraph
            graph={graph}
            selectedNode={state.selectedNode}
            onNodeClick={node => dispatch(SelectNode(node.id))}
          />
          <ArtifactTimeline graph={graph} />
          <ProjectCategories graph={graph} />
        </div>
      | (_, None, _) => <div>{"No data"->React.string}</div>
      }}
    </main>
  </div>
}
```

### Conversation Graph Component

```rescript
// components/ConversationGraph.res

@react.component
let make = (~graph: Domain.graph, ~selectedNode, ~onNodeClick) => {
  let reagraphNodes = graph.nodes->Array.map(Reagraph.toReagraphNode)
  let reagraphEdges = graph.edges->Array.map(Reagraph.toReagraphEdge)

  <div className="conversation-graph">
    <Reagraph.GraphCanvas
      nodes={reagraphNodes}
      edges={reagraphEdges}
      draggable={true}
      onNodeClick={node => {
        // Find domain node by ID
        graph.nodes
          ->Array.find(n => Domain.nodeIdToString(n.id) == node.id)
          ->Option.forEach(onNodeClick)
      }}
    />

    {switch selectedNode {
    | None => React.null
    | Some(nodeId) =>
      switch graph.nodes->Array.find(n => n.id == nodeId) {
      | None => React.null
      | Some(node) => <NodeDetails node={node} />
      }
    }}
  </div>
}
```

## Testing

### Unit Tests (Jest)

```javascript
// __tests__/ColorMixing.test.js
import { mixColors } from '../src/transforms/ColorMixing.bs.js';

test('mixColors returns gray for empty memberships', () => {
  expect(mixColors([])).toBe('#999999');
});

test('mixColors blends multiple projects', () => {
  const memberships = [
    { projectId: 'anamnesis', strength: 0.6 },
    { projectId: 'rescript-evangeliser', strength: 0.4 },
  ];

  const result = mixColors(memberships);
  expect(result).toMatch(/^rgb\(\d+, \d+, \d+\)$/);
});
```

### Component Tests (React Testing Library)

```javascript
// __tests__/ConversationGraph.test.js
import { render, screen } from '@testing-library/react';
import { make as ConversationGraph } from '../src/components/ConversationGraph.bs.js';

test('renders graph canvas', () => {
  const graph = {
    nodes: [{ id: { TAG: 0, _0: 'msg-1' }, label: 'Test', /* ... */ }],
    edges: [],
  };

  render(<ConversationGraph graph={graph} selectedNode={null} onNodeClick={() => {}} />);

  expect(screen.getByClassName('conversation-graph')).toBeInTheDocument();
});
```

## Performance

### Memoization

```rescript
let expensiveComputation = React.useMemo1(
  () => {
    // Heavy computation
    processLargeGraph(graph)
  },
  [graph]  // Only recompute when graph changes
)
```

### Virtual Scrolling

```rescript
// For large lists
module VirtualList = {
  @react.component
  let make = (~items: array<'a>, ~renderItem: 'a => React.element) => {
    let (visibleRange, setVisibleRange) = React.useState(() => (0, 50))

    let visibleItems = items->Array.slice(
      ~start=fst(visibleRange),
      ~end=snd(visibleRange)
    )

    <div className="virtual-list" onScroll={handleScroll}>
      {visibleItems->Array.map(renderItem)->React.array}
    </div>
  }
}
```

### Debounced Search

```rescript
let useDebounce = (value, delay) => {
  let (debouncedValue, setDebouncedValue) = React.useState(() => value)

  React.useEffect2(() => {
    let timeoutId = setTimeout(() => setDebouncedValue(_ => value), delay)
    Some(() => clearTimeout(timeoutId))
  }, (value, delay))

  debouncedValue
}

// Usage
let searchText = /* ... */
let debouncedSearch = useDebounce(searchText, 300)  // 300ms delay
```

## Deployment

### Production Build

```bash
npm run build
# Output in dist/
```

### Serve Static Files

```nginx
# nginx.conf
server {
    listen 80;
    root /var/www/anamnesis/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:4000;
    }
}
```

## Troubleshooting

### Type Errors

ReScript provides clear compiler errors. Read them carefully:

```
Error: This has type:
  string
But somewhere wanted:
  int
```

### ReScript Compilation Fails

```bash
# Clean build
npx rescript clean
npx rescript build
```

### Reagraph Not Rendering

Check WebGL support:

```javascript
const canvas = document.createElement('canvas');
const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
console.log('WebGL supported:', !!gl);
```

## References

- [ReScript Documentation](https://rescript-lang.org/docs/manual/latest/introduction)
- [ReScript React](https://rescript-lang.org/docs/react/latest/introduction)
- [Reagraph](https://reagraph.dev/)
- [rescript-recharts](https://github.com/minnozz/rescript-recharts)
- Research: `/docs/research/rescript-visualization.adoc`
- Architecture: `/docs/architecture/system-architecture.adoc`

## Next Steps

1. Create Reagraph bindings
2. Implement ConversationGraph component
3. Build ArtifactTimeline with rescript-recharts
4. Add SearchFilter component
5. Integrate API client
6. Test with mock data
7. Connect to Elixir backend
