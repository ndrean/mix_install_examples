Application.put_env(:example, Example.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "~> 1.7.0-rc.2", override: true},
  {:phoenix_live_view, "~> 0.18.2"}
])

defmodule Example.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Example.ExampleLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  def render("live.html", assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.0-rc.2/priv/static/phoenix.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.2/priv/static/phoenix_live_view.min.js"></script>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/js/bootstrap.bundle.min.js"></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <%= @inner_content %>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-5 my-5 text-center">
      <span class="text-monospace"><%= @count %></span>
      <button class="btn btn-outline-primary" phx-click="inc">+</button>
      <button class="btn btn-outline-primary" phx-click="dec">-</button>
    </div>
    """
  end

  def handle_event("inc", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count - 1)}
  end
end

defmodule Example.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", Example do
    pipe_through(:browser)

    live("/", ExampleLive, :index)
  end
end

defmodule Example.Endpoint do
  use Phoenix.Endpoint, otp_app: :example
  socket("/live", Phoenix.LiveView.Socket)
  plug(Example.Router)
end

{:ok, _} = Supervisor.start_link([Example.Endpoint], strategy: :one_for_one)
Process.sleep(:infinity)
