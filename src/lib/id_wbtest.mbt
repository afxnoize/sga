///|
test "adjectives array has 10 elements" {
  inspect(adjectives.length(), content="10")
}

///|
test "colors array has 10 elements" {
  inspect(colors.length(), content="10")
}

///|
test "animals array has 10 elements" {
  inspect(animals.length(), content="10")
}

///|
test "adjectives contains expected values" {
  inspect(adjectives[0], content="quiet")
  inspect(adjectives[1], content="bold")
  inspect(adjectives[9], content="wild")
}

///|
test "colors contains expected values" {
  inspect(colors[0], content="lime")
  inspect(colors[1], content="azure")
  inspect(colors[9], content="sage")
}

///|
test "animals contains expected values" {
  inspect(animals[0], content="rabbit")
  inspect(animals[1], content="fox")
  inspect(animals[9], content="crow")
}

///|
test "random_element returns element from array" {
  let result = random_element(adjectives)
  let found = adjectives.iter().any(fn(a) { a == result })
  inspect(found, content="true")
}

///|
test "generate_id returns properly formatted id" {
  let id = generate_id()
  let parts = id.split("_").collect()
  inspect(parts.length(), content="4")
  inspect(parts[0].length(), content="10")
}
