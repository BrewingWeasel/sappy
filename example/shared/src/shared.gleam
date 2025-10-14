import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/result
import sappy

pub type Task {
  Task(title: String, description: String, completed: Bool)
}

pub fn default_task() {
  Task(title: "New Task", description: "This is a new task", completed: False)
}

fn task_to_json(task: Task) -> json.Json {
  let Task(title:, description:, completed:) = task
  json.object([
    #("title", json.string(title)),
    #("description", json.string(description)),
    #("completed", json.bool(completed)),
  ])
}

fn task_decoder() -> decode.Decoder(Task) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use completed <- decode.field("completed", decode.bool)
  decode.success(Task(title:, description:, completed:))
}

pub fn base_endpoint(path) {
  sappy.new("localhost:8000", path) |> sappy.with_scheme(http.Http)
}

pub fn get_all_tasks() -> sappy.EndPoint(Nil, List(#(Int, Task))) {
  base_endpoint("/api/tasks")
  |> sappy.with_method(http.Get)
  |> sappy.returning_json(
    to_json: json.array(_, fn(pair) {
      let #(id, task) = pair
      json.preprocessed_array([json.int(id), task_to_json(task)])
    }),
    decoder: decode.list({
      use id <- decode.then(decode.at([0], decode.int))
      use task <- decode.then(decode.at([1], task_decoder()))

      decode.success(#(id, task))
    }),
  )
}

pub fn create_task() -> sappy.EndPoint(Task, Int) {
  base_endpoint("/api/tasks/new")
  |> sappy.with_method(http.Post)
  |> sappy.with_json_body(task_to_json, task_decoder())
  |> sappy.returning_json(json.int, decode.int)
}

pub fn complete_task() -> sappy.EndPoint(Int, Nil) {
  base_endpoint("/api/tasks/id/$id/complete")
  |> sappy.with_method(http.Post)
  |> sappy.with_parameters_as_input(
    fn(title) { dict.from_list([#("id", int.to_string(title))]) },
    fn(parameters) { dict.get(parameters, "id") |> result.try(int.parse) },
  )
}
