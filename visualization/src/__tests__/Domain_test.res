open Jest
open Expect

describe("Domain Types", () => {
  open Domain

  test("MessageId construction", () => {
    let msgId = MessageId("msg-001")
    expect(msgId)->toBeTruthy
  })

  test("ArtifactId construction", () => {
    let artId = ArtifactId("art-001")
    expect(artId)->toBeTruthy
  })

  test("NodeId variants", () => {
    let messageNode = MessageNode(MessageId("msg-001"))
    let artifactNode = ArtifactNode(ArtifactId("art-001"))

    expect((messageNode, artifactNode))->toBeTruthy
  })

  test("ProjectMembership structure", () => {
    let membership: projectMembership = {
      projectId: "anamnesis",
      strength: 0.8,
    }

    expect(membership.projectId)->toEqual("anamnesis")
    expect(membership.strength)->toEqual(0.8)
  })

  test("Message record structure", () => {
    let msg: message = {
      id: MessageId("msg-001"),
      role: User,
      content: "Hello, Claude",
      timestamp: 1732272000.0,
      artifacts: [],
      projectMemberships: [{projectId: "test-project", strength: 1.0}],
    }

    expect(msg.role)->toEqual(User)
    expect(msg.content)->toEqual("Hello, Claude")
    expect(Array.length(msg.artifacts))->toEqual(0)
  })

  test("Artifact record structure", () => {
    let artifact: artifact = {
      id: ArtifactId("art-001"),
      artifactType: Code,
      title: Some("example.res"),
      content: "let x = 1",
      language: Some("rescript"),
      lifecycleState: Created,
      projectMemberships: [{projectId: "anamnesis", strength: 1.0}],
    }

    expect(artifact.artifactType)->toEqual(Code)
    expect(artifact.lifecycleState)->toEqual(Created)
  })

  test("LifecycleState variants", () => {
    let states = [Created, Modified, Removed, Evaluated]
    expect(Array.length(states))->toEqual(4)
  })

  test("Role variants", () => {
    let userRole = User
    let assistantRole = Assistant

    expect((userRole, assistantRole))->toBeTruthy
  })

  test("ArtifactType variants", () => {
    let types = [Code, Document, Image, Data, Other]
    expect(Array.length(types))->toEqual(5)
  })

  test("Conversation structure with multiple messages", () => {
    let conv: conversation = {
      id: "conv-001",
      platform: Some("Claude"),
      timestamp: 1732272000.0,
      messages: [
        {
          id: MessageId("msg-1"),
          role: User,
          content: "First message",
          timestamp: 1732272000.0,
          artifacts: [],
          projectMemberships: [{projectId: "test", strength: 1.0}],
        },
        {
          id: MessageId("msg-2"),
          role: Assistant,
          content: "Second message",
          timestamp: 1732272010.0,
          artifacts: [],
          projectMemberships: [{projectId: "test", strength: 1.0}],
        },
      ],
      projectMemberships: [{projectId: "test", strength: 1.0}],
    }

    expect(Array.length(conv.messages))->toEqual(2)
    expect(conv.platform)->toEqual(Some("Claude"))
  })

  test("Multi-project membership", () => {
    let memberships: array<projectMembership> = [
      {projectId: "anamnesis", strength: 0.8},
      {projectId: "zotero-voyant", strength: 0.3},
      {projectId: "rescript-evangeliser", strength: 0.1},
    ]

    expect(Array.length(memberships))->toEqual(3)

    let totalStrength = memberships->Array.reduce(0.0, (acc, m) => acc +. m.strength)
    expect(totalStrength)->toBeCloseTo(1.2)
  })

  test("Edge structure", () => {
    let edge: edge = {
      source: MessageNode(MessageId("msg-1")),
      target: ArtifactNode(ArtifactId("art-1")),
      edgeType: CreatesArtifact,
    }

    expect(edge.edgeType)->toEqual(CreatesArtifact)
  })

  test("EdgeType variants", () => {
    let types = [
      CreatesArtifact,
      ModifiesArtifact,
      ReferencesArtifact,
      ResponseTo,
      SameProject,
    ]
    expect(Array.length(types))->toEqual(5)
  })

  test("Graph structure", () => {
    let graph: graph = {
      nodes: [
        MessageNode(MessageId("msg-1")),
        ArtifactNode(ArtifactId("art-1")),
      ],
      edges: [
        {
          source: MessageNode(MessageId("msg-1")),
          target: ArtifactNode(ArtifactId("art-1")),
          edgeType: CreatesArtifact,
        },
      ],
      conversations: [],
    }

    expect(Array.length(graph.nodes))->toEqual(2)
    expect(Array.length(graph.edges))->toEqual(1)
  })
})
