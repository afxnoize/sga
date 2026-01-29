///|
let adjectives : Array[String] = [
  "quiet", "bold", "swift", "calm", "bright", "warm", "cool", "soft", "sharp", "wild",
]

///|
let colors : Array[String] = [
  "lime", "azure", "coral", "amber", "ivory", "jade", "ruby", "pearl", "onyx", "sage",
]

///|
let animals : Array[String] = [
  "rabbit", "fox", "hawk", "owl", "wolf", "bear", "deer", "lynx", "seal", "crow",
]

///|
extern "js" fn math_random() -> Double =
  #|() => Math.random()

///|
fn random_element(arr : Array[String]) -> String {
  let idx = (math_random() * arr.length().to_double()).to_int()
  arr[idx]
}

///|
extern "js" fn get_today_utc() -> String =
  #|() => new Date().toISOString().slice(0, 10)

///|
pub fn generate_id() -> String {
  let date = get_today_utc()
  let adj = random_element(adjectives)
  let color = random_element(colors)
  let animal = random_element(animals)
  "\{date}_\{adj}_\{color}_\{animal}"
}
