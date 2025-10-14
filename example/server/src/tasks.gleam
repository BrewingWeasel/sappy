import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import shared

type State {
  State(tasks: List(#(Int, shared.Task)), current_task_id: Int)
}

pub fn new() {
  let assert Ok(actor) =
    actor.new(State([], 0))
    |> actor.on_message(handle_message)
    |> actor.start
  actor
}

pub type Actor =
  actor.Started(process.Subject(Message))

pub type Message {
  GetAllTasks(send_to: process.Subject(List(#(Int, shared.Task))))
  AddTask(shared.Task, send_to: process.Subject(Int))
  ToggleTaskCompleted(Int)
}

pub fn get_all_tasks(actor: Actor) {
  actor.call(actor.data, 1000, GetAllTasks)
}

pub fn toggle_task_completed(actor: Actor, task_id: Int) -> Nil {
  actor.send(actor.data, ToggleTaskCompleted(task_id))
}

pub fn add_task(actor: Actor, task: shared.Task) -> Int {
  actor.call(actor.data, 1000, AddTask(task, _))
}

fn handle_message(state: State, message: Message) {
  case message {
    GetAllTasks(respond_to) -> {
      process.send(respond_to, state.tasks)
      actor.continue(state)
    }
    AddTask(task, respond_to) -> {
      process.send(respond_to, state.current_task_id)
      actor.continue(State(
        [#(state.current_task_id, task), ..state.tasks],
        state.current_task_id + 1,
      ))
    }
    ToggleTaskCompleted(id) -> {
      let tasks =
        list.map(state.tasks, fn(pair) {
          let #(task_id, task) = pair
          case task_id == id {
            True -> #(task_id, shared.Task(..task, completed: !task.completed))
            False -> pair
          }
        })
      actor.continue(State(..state, tasks:))
    }
  }
}
