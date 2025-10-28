import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/json
import sappy

fn base_endpoint(path: String) {
  sappy.new("localhost:8000", path) |> sappy.with_scheme(http.Http)
}

pub type Person {
  Person(name: String, age: Int, is_student: Bool)
}

fn person_to_json(person: Person) -> json.Json {
  let Person(name:, age:, is_student:) = person
  json.object([
    #("name", json.string(name)),
    #("age", json.int(age)),
    #("is_student", json.bool(is_student)),
  ])
}

fn person_decoder() -> decode.Decoder(Person) {
  use name <- decode.field("name", decode.string)
  use age <- decode.field("age", decode.int)
  use is_student <- decode.field("is_student", decode.bool)
  decode.success(Person(name:, age:, is_student:))
}

pub fn get_person() -> sappy.EndPoint(String, Person) {
  base_endpoint("/api/get/$name")
  |> sappy.with_method(http.Get)
  |> sappy.with_parameters_as_input(
    fn(name: String) { dict.from_list([#("name", name)]) },
    dict.get(_, "name"),
  )
  |> sappy.returning_json(person_to_json, person_decoder())
}
