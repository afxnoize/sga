///|
test "format_tags_yaml returns [] for empty array" {
  let result = format_tags_yaml([])
  inspect(result, content="[]")
}

///|
test "format_tags_yaml formats single tag" {
  let result = format_tags_yaml(["moonbit"])
  inspect(result, content=(
    #|
    #|  - moonbit
  ))
}

///|
test "format_tags_yaml formats multiple tags" {
  let result = format_tags_yaml(["moonbit", "test", "tdd"])
  inspect(result, content=(
    #|
    #|  - moonbit
    #|  - test
    #|  - tdd
  ))
}
