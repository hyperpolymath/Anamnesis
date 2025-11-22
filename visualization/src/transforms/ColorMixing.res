// Fuzzy Category Color Mixing
// Mix colors based on project membership strengths

type rgb = {r: int, g: int, b: int}

let projectColors = Map.String.fromArray([
  ("anamnesis", {r: 72, g: 187, b: 120}),           // Green
  ("rescript-evangeliser", {r: 230, g: 74, b: 25}), // Orange/Red
  ("zotero-nsai", {r: 52, g: 152, b: 219}),         // Blue
  ("fogbinder", {r: 156, g: 39, b: 176}),           // Purple
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

// Get color for a single project
let getProjectColor = (projectId: string): string => {
  switch projectColors->Map.String.get(projectId) {
  | None => "#999999"
  | Some({r, g, b}) => `rgb(${Int.toString(r)}, ${Int.toString(g)}, ${Int.toString(b)})`
  }
}
