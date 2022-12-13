defmodule HaytniTestWeb.Haytni.Dummy.View do
  require EEx

  def render("test.html", assigns) do
    EEx.eval_string("<p>Hello <%= @user.firstname %>!</p>", assigns: assigns, engine: Phoenix.HTML.Engine)
  end

  def render("test.text", assigns) do
    EEx.eval_string("Hello <%= @user.firstname %>!", assigns: assigns)
  end
end

defmodule HaytniWeb.EmailCase do
  defmacro __using__(options \\ [])

  use ExUnit.CaseTemplate

  defmacro __using__(options) do
    {options, quoted} = Haytni.Case.haytni_common(options)
    quote do
      unquote(super(options))

      import unquote(__MODULE__)
      import Haytni.TestHelpers

      unquote(quoted)
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(HaytniTest.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(HaytniTest.Repo, {:shared, self()})
    end

    :ok
  end

  @spec dummy_email(module :: module) :: Haytni.Mail.t
  def dummy_email(module) do
    Haytni.Mail.new()
    |> Haytni.Mail.assign(:user, %HaytniTest.User{firstname: "jean"})
    |> Haytni.Mail.to("jean.pierre@gmail.com")
    |> Haytni.Mail.subject("You received a new friend request")
    |> Haytni.Mail.put_view(module, "Dummy.View")
    |> Haytni.Mail.put_html_template("test.html")
    |> Haytni.Mail.put_text_template("test.text")
  end

  @spec dummy_attributes() :: Keyword.t
  def dummy_attributes do
    # NOTE: Bamboo.Test.assert_delivered_email requires from + to else fails with "There were 0 emails delivered to this process."
    [
      to: "x@y.z",
      from: "a@b.c",
      subject: "something",
    ]
  end
end
