import gleam/io
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import sappy_rsvp
import shared

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    tasks: List(#(Int, shared.Task)),
    current_title: String,
    current_description: String,
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(tasks: [], current_title: "", current_description: ""),
    sappy_rsvp.send(shared.get_all_tasks(), Nil, TasksReceived),
  )
}

pub type Msg {
  CreateTask
  ToggleTaskCompleted(Int)

  TaskCreated(Result(Int, sappy_rsvp.Error), shared.Task)
  TasksReceived(Result(List(#(Int, shared.Task)), sappy_rsvp.Error))

  UpdateTitle(String)
  UpdateDescription(String)
  ServerCompletedTask(Result(Nil, sappy_rsvp.Error))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case echo msg {
    CreateTask -> {
      let new_task =
        shared.Task(
          title: model.current_title,
          description: model.current_description,
          completed: False,
        )

      #(
        Model(..model, current_title: "", current_description: ""),
        sappy_rsvp.send(shared.create_task(), new_task, TaskCreated(_, new_task)),
      )
    }
    ToggleTaskCompleted(id) -> {
      #(
        Model(
          ..model,
          tasks: list.map(model.tasks, fn(pair) {
            let #(task_id, task) = pair
            case task_id == id {
              True -> #(
                task_id,
                shared.Task(..task, completed: !task.completed),
              )
              False -> pair
            }
          }),
        ),
        sappy_rsvp.send(shared.complete_task(), id, ServerCompletedTask),
      )
    }

    TasksReceived(result) -> {
      use tasks <- log_error(result, model)
      #(Model(..model, tasks: tasks), effect.none())
    }
    TaskCreated(result, task) -> {
      use id <- log_error(result, model)
      #(Model(..model, tasks: [#(id, task), ..model.tasks]), effect.none())
    }
    ServerCompletedTask(result) -> {
      use _ <- log_error(result, model)
      #(model, effect.none())
    }

    UpdateTitle(title) -> #(Model(..model, current_title: title), effect.none())
    UpdateDescription(description) -> #(
      Model(..model, current_description: description),
      effect.none(),
    )
  }
}

fn log_error(result, model, continue_with) {
  case result {
    Ok(v) -> continue_with(v)
    Error(e) -> {
      io.println_error("Error calling API: " <> string.inspect(e))
      #(model, effect.none())
    }
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let can_create =
    !string.is_empty(string.trim(model.current_title))
    && !string.is_empty(string.trim(model.current_description))

  html.div(
    [
      attribute.class(
        "bg-rose-50 flex flex-col w-screen h-screen items-center justify-start pt-8 px-4",
      ),
    ],
    [
      html.div(
        [
          attribute.class(
            "bg-white shadow-lg rounded-lg p-6 mb-6 w-full max-w-2xl",
          ),
        ],
        [
          html.div([attribute.class("flex flex-col gap-3 mb-4")], [
            html.input([
              event.on_input(UpdateTitle),
              attribute.value(model.current_title),
              attribute.placeholder("Task title"),
              attribute.class(
                "px-4 py-2 border-2 border-rose-200 rounded-lg focus:outline-none focus:border-rose-500 focus:ring-2 focus:ring-rose-300",
              ),
            ]),
            html.input([
              event.on_input(UpdateDescription),
              attribute.value(model.current_description),
              attribute.placeholder("Task description"),
              attribute.class(
                "px-4 py-2 border-2 border-rose-200 rounded-lg focus:outline-none focus:border-rose-500 focus:ring-2 focus:ring-rose-300",
              ),
            ]),
          ]),
          html.button(
            [
              event.on_click(CreateTask),
              attribute.class(
                "w-full bg-rose-500 cursor-pointer disabled:bg-gray-500 disabled:cursor-not-allowed hover:bg-rose-600 active:bg-rose-700 text-white font-semibold py-2 px-4 rounded-lg transition duration-200 shadow-md hover:shadow-lg hover:disabled:shadow-none",
              ),
              attribute.disabled(!can_create),
            ],
            [element.text("Create Task")],
          ),
        ],
      ),
      html.div(
        [
          attribute.class(
            "bg-white rounded-lg shadow-lg w-full max-w-4xl max-h-[60%] overflow-scroll",
          ),
        ],
        [
          html.table([attribute.class("w-full border-collapse")], [
            html.thead([attribute.class("bg-rose-500")], [
              html.tr([], [
                html.th(
                  [
                    attribute.class(
                      "px-6 py-3 text-left text-white font-semibold w-1/3",
                    ),
                  ],
                  [element.text("Title")],
                ),
                html.th(
                  [
                    attribute.class(
                      "px-6 py-3 text-left text-white font-semibold w-1/3",
                    ),
                  ],
                  [element.text("Description")],
                ),
                html.th(
                  [
                    attribute.class(
                      "px-6 py-3 text-center text-white font-semibold w-1/3",
                    ),
                  ],
                  [element.text("Completed")],
                ),
              ]),
            ]),
            html.tbody([], list.map(model.tasks, view_task)),
          ]),
        ],
      ),
    ],
  )
}

fn view_task(task_pair: #(Int, shared.Task)) -> element.Element(Msg) {
  let #(id, task) = task_pair
  html.tr(
    [
      attribute.class(
        "border-b border-rose-100 hover:bg-rose-50 transition duration-150",
      ),
    ],
    [
      html.td([attribute.class("px-6 py-4 text-gray-900 font-medium")], [
        element.text(task.title),
      ]),
      html.td([attribute.class("px-6 py-4 text-gray-700")], [
        element.text(task.description),
      ]),
      html.td([attribute.class("px-6 py-4 text-center")], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(task.completed),
          event.on_change(fn(_) { ToggleTaskCompleted(id) }),
          attribute.class(
            "w-5 h-5 accent-rose-500 cursor-pointer rounded-lg focus:ring-2 focus:ring-rose-300",
          ),
        ]),
      ]),
    ],
  )
}
