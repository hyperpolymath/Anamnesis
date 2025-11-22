// Anamnesis Domain Types
// Type-safe representation of conversation graphs

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

// Artifact states
type lifecycleState =
  | Created
  | Modified
  | Removed
  | Evaluated

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
  state: option<lifecycleState>,
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

// Utility functions

let nodeIdToString = (id: nodeId): string => {
  switch id {
  | MessageNode(MessageId(s)) => s
  | ArtifactNode(ArtifactId(s)) => s
  }
}

let edgeTypeToString = (et: edgeType): string => {
  switch et {
  | Contains => "contains"
  | References => "references"
  | CreatedIn => "created_in"
  | ModifiedIn => "modified_in"
  | Evaluates => "evaluates"
  }
}

let lifecycleStateToString = (state: lifecycleState): string => {
  switch state {
  | Created => "created"
  | Modified => "modified"
  | Removed => "removed"
  | Evaluated => "evaluated"
  }
}
