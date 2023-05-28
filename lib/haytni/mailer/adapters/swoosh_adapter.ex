defmodule Haytni.Mailer.SwooshAdapter do
  @moduledoc """
  This is the ready to use mail adapter for Swoosh.

  If you use Swoosh, write your mailer like the following:

  ```elixir
  defmodule MyApp.Mailer do
    use Haytni.Mailer, [
      otp_app: :my_app,
      adapter: #{inspect(__MODULE__)},
    ]

    def from, do: {"mydomain.com", "noreply@mydomain.com"}
  end
  ```
  """

  defmacro __using__(options) do
    otp_app = Keyword.fetch!(options, :otp_app)

    quote do
      use Haytni.Mailer.Adapter
      use Swoosh.Mailer, otp_app: unquote(otp_app)

      @impl Haytni.Mailer.Adapter
      def cast(email = %Haytni.Mail{}, mailer, options) do
        unquote(__MODULE__).cast(email, __MODULE__, options)
      end

      @impl Haytni.Mailer.Adapter
      def send(email = %{__struct__: Swoosh.Email}, mailer, options) do
        unquote(__MODULE__).send(email, __MODULE__, options)
      end
    end
  end

  use Haytni.Mailer.Adapter

  @impl Haytni.Mailer.Adapter
  def cast(email = %Haytni.Mail{}, mailer, _options) do
    Enum.reduce(
      email.headers,
      Swoosh.Email.new(),
      fn {name, value}, email_as_acc ->
        Swoosh.Email.header(email_as_acc, name, value)
      end
    )
    |> Swoosh.Email.put_to(email.to)
    |> Swoosh.Email.from(mailer.from())
    |> Swoosh.Email.subject(email.subject)
    |> Swoosh.Email.html_body(email.html_body)
    |> Swoosh.Email.text_body(email.text_body)
  end

  @impl Haytni.Mailer.Adapter
  def send(email = %{__struct__: Swoosh.Email}, mailer, options) do
    email
    |> mailer.deliver(options)
  end
end
