defmodule Haytni.Mailer.BambooAdapter do
  @moduledoc """
  This is the ready to use mail adapter for Bamboo.

  If you use Bamboo, write your mailer like the following:

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
      use Bamboo.Mailer, otp_app: unquote(otp_app)

      @impl Haytni.Mailer.Adapter
      def cast(email = %Haytni.Mail{}, mailer, options) do
        unquote(__MODULE__).cast(email, __MODULE__, options)
      end

      @impl Haytni.Mailer.Adapter
      def send(email = %{__struct__: Bamboo.Email}, mailer, options) do
        unquote(__MODULE__).send(email, __MODULE__, options)
      end
    end
  end

  use Haytni.Mailer.Adapter

  @impl Haytni.Mailer.Adapter
  def cast(email = %Haytni.Mail{}, mailer, _options) do
    Bamboo.Email.new_email()
    |> Bamboo.Email.to(email.to)
    |> Bamboo.Email.from(mailer.from())
    |> Bamboo.Email.subject(email.subject)
    |> Bamboo.Email.html_body(email.html_body)
    |> Bamboo.Email.text_body(email.text_body)
  end

  @impl Haytni.Mailer.Adapter
  def send(email = %{__struct__: Bamboo.Email}, mailer, options) do
    email
    |> mailer.deliver_now(options)
  end
end
