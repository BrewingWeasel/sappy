import gleam/erlang/process
import gleam/http/response
import mist
import sappy_wisp
import shared
import tasks
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let tasks_db = tasks.new()

  let assert Ok(_) =
    wisp_mist.handler(handle_request(_, tasks_db), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- force_cors()

  handle_request(req)
}

fn handle_request(req: wisp.Request, tasks: tasks.Actor) -> wisp.Response {
  use req <- middleware(req)

  use <- sappy_wisp.handle_request(
    shared.get_all_tasks(),
    req,
    fn(_input, respond_with) { respond_with(tasks.get_all_tasks(tasks)) },
  )

  use <- sappy_wisp.handle_request(
    shared.complete_task(),
    req,
    fn(task_id, _respond_with) {
      tasks.toggle_task_completed(tasks, task_id)
      wisp.ok()
    },
  )

  use <- sappy_wisp.handle_request(
    shared.create_task(),
    req,
    fn(input, respond_with) { respond_with(tasks.add_task(tasks, input)) },
  )

  case wisp.path_segments(req) {
    [] -> wisp.ok() |> wisp.html_body("Hi!")
    _ -> wisp.not_found()
  }
}

// Needed for this example because the lustre frontend is being run separately
fn force_cors(run: fn() -> wisp.Response) -> wisp.Response {
  run() |> response.prepend_header("Access-Control-Allow-Origin", "http://localhost:1234")
}
