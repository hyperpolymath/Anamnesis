open Jest
open Expect
open Domain

describe("ColorMixing", () => {
  test("single project returns base color", () => {
    let memberships = [{projectId: "anamnesis", strength: 1.0}]
    let color = ColorMixing.mixColors(memberships)

    // Should return a valid CSS color string
    expect(color)->toMatch(%re("/^rgb\(/"))
  })

  test("no memberships returns gray", () => {
    let memberships = []
    let color = ColorMixing.mixColors(memberships)

    // Should return gray/neutral color
    expect(color)->toMatch(%re("/^rgb\(/"))
    expect(color)->toEqual("rgb(128, 128, 128)")
  })

  test("equal 50/50 mix of two projects", () => {
    let memberships = [
      {projectId: "project-a", strength: 0.5},
      {projectId: "project-b", strength: 0.5},
    ]
    let color = ColorMixing.mixColors(memberships)

    expect(color)->toMatch(%re("/^rgb\(/"))
    // Color should be blend of two base colors
    expect(color)->not->toEqual("rgb(128, 128, 128)")
  })

  test("dominant project (80/20 mix)", () => {
    let memberships = [
      {projectId: "dominant", strength: 0.8},
      {projectId: "minor", strength: 0.2},
    ]
    let color = ColorMixing.mixColors(memberships)

    // Should be closer to dominant project's color
    expect(color)->toMatch(%re("/^rgb\(/"))
  })

  test("three-way split", () => {
    let memberships = [
      {projectId: "project-a", strength: 0.5},
      {projectId: "project-b", strength: 0.3},
      {projectId: "project-c", strength: 0.2},
    ]
    let color = ColorMixing.mixColors(memberships)

    expect(color)->toMatch(%re("/^rgb\(/"))
  })

  test("normalizes strengths that don't sum to 1.0", () => {
    // Strengths sum to 2.0
    let memberships = [
      {projectId: "project-a", strength: 1.0},
      {projectId: "project-b", strength: 1.0},
    ]
    let color = ColorMixing.mixColors(memberships)

    // Should normalize and still produce valid color
    expect(color)->toMatch(%re("/^rgb\(/"))
  })

  test("very small membership strength", () => {
    let memberships = [
      {projectId: "main-project", strength: 0.99},
      {projectId: "tangential", strength: 0.01},
    ]
    let color = ColorMixing.mixColors(memberships)

    // Should still work with very small values
    expect(color)->toMatch(%re("/^rgb\(/"))
  })

  test("color output is valid CSS rgb format", () => {
    let memberships = [{projectId: "test", strength: 1.0}]
    let color = ColorMixing.mixColors(memberships)

    // Should match rgb(r, g, b) format with values 0-255
    expect(color)->toMatch(%re("/^rgb\(\d{1,3}, \d{1,3}, \d{1,3}\)$/"))
  })

  test("getProjectColor returns consistent color for same project", () => {
    let color1 = ColorMixing.getProjectColor("anamnesis")
    let color2 = ColorMixing.getProjectColor("anamnesis")

    expect(color1)->toEqual(color2)
  })

  test("different projects get different colors", () => {
    let color1 = ColorMixing.getProjectColor("project-a")
    let color2 = ColorMixing.getProjectColor("project-b")

    expect(color1)->not->toEqual(color2)
  })

  test("parseColor extracts RGB values", () => {
    let rgbColor = "rgb(255, 128, 64)"
    let parsed = ColorMixing.parseColor(rgbColor)

    switch parsed {
    | Some({r, g, b}) =>
      expect(r)->toEqual(255)
      expect(g)->toEqual(128)
      expect(b)->toEqual(64)
    | None => fail("Should parse valid RGB color")
    }
  })

  test("parseColor handles invalid format", () => {
    let invalidColor = "not a color"
    let parsed = ColorMixing.parseColor(invalidColor)

    expect(parsed)->toEqual(None)
  })

  test("blendColors averages two colors", () => {
    let color1 = {ColorMixing.r: 100, g: 100, b: 100}
    let color2 = {ColorMixing.r: 200, g: 200, b: 200}

    let blended = ColorMixing.blendColors(color1, color2, 0.5)

    expect(blended.r)->toEqual(150)
    expect(blended.g)->toEqual(150)
    expect(blended.b)->toEqual(150)
  })

  test("blendColors with weight 0.0 returns first color", () => {
    let color1 = {ColorMixing.r: 100, g: 100, b: 100}
    let color2 = {ColorMixing.r: 200, g: 200, b: 200}

    let blended = ColorMixing.blendColors(color1, color2, 0.0)

    expect(blended.r)->toEqual(100)
    expect(blended.g)->toEqual(100)
    expect(blended.b)->toEqual(100)
  })

  test("blendColors with weight 1.0 returns second color", () => {
    let color1 = {ColorMixing.r: 100, g: 100, b: 100}
    let color2 = {ColorMixing.r: 200, g: 200, b: 200}

    let blended = ColorMixing.blendColors(color1, color2, 1.0)

    expect(blended.r)->toEqual(200)
    expect(blended.g)->toEqual(200)
    expect(blended.b)->toEqual(200)
  })

  test("clamps RGB values to 0-255 range", () => {
    let color = ColorMixing.rgbToString({r: 300, g: -50, b: 128})

    // Should clamp to valid range
    expect(color)->toMatch(%re("/^rgb\(255, 0, 128\)$/"))
  })
})
