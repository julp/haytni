defmodule Haytni.Mailer.TestAdapter do
  @moduledoc """
  TODO (doc)
  """

  defmacro __using__(_options) do
    quote do
      use Haytni.Mailer.Adapter

      @impl Haytni.Mailer.Adapter
      def cast(email = %Haytni.Mail{}, mailer, options) do
        unquote(__MODULE__).cast(email, __MODULE__, options)
      end

      @impl Haytni.Mailer.Adapter
      def send(email = %Haytni.Mail{}, mailer, options) do
        unquote(__MODULE__).send(email, __MODULE__, options)
      end
    end
  end

  use Haytni.Mailer.Adapter
  import ExUnit.Assertions

  @impl Haytni.Mailer.Adapter
  def cast(email = %Haytni.Mail{}, _mailer, _options) do
    email
  end

  @impl Haytni.Mailer.Adapter
  def send(email = %Haytni.Mail{}, _mailer, _options) do
    pid = Application.get_env(:haytni, :shared_test_process) || self()
    send(pid, {__MODULE__, email})
  end

  defp assert_match(value, pattern)
    when is_function(pattern, 1)
  do
    assert pattern.(value)
  end

  defp assert_match(value, pattern)
    when is_struct(pattern, Regex) # or is_binary(pattern)
  do
    assert value =~ pattern
  end

  defp assert_match(value, pattern) do
    assert value == pattern
  end

  defp assert_match(email, field, pattern)
    when field in ~W[from to subject html_body text_body headers views]a
  do
    email
    |> Map.get(field)
    |> assert_match(pattern)
  end

  defp assert_match(email, header, pattern) do
    header =
      header
      |> to_string()
      |> String.downcase()

    assert_match(email.headers[header], pattern)
  end

  defp to_enumerable(email = %Haytni.Mail{})
#     when is_struct(email)
  do
    email
    |> Map.from_struct()
    |> Map.drop(~W[assigns]a)
  end

  defp to_enumerable(email) do
    email
  end

#   defp do_assert_email_sent(email = %Haytni.Mail{}, timeout, failure_message) do
#     email = %{email | assigns: %{}}
#     assert_receive({__MODULE__, ^email}, timeout, failure_message)
#   end

  defp do_assert_email_sent(matches, timeout, failure_message) do
    assert_receive({__MODULE__, email}, timeout, failure_message)
    email = %{email | assigns: %{}}
    matches = %{matches | assigns: %{}}
    assert email == matches
    matches
    |> to_enumerable()
    |> Enum.each(
      fn {k, v} ->
        assert_match(email, k, v)
      end
    )
  end

  @doc ~S"""
  Asserts an email was sent and matches *email* (its internal data - headers and body)

  ```elixir
  # email is the **whole** (direct pattern matching) expected %Haytni.Mail{} from some function generating it
  assert_email_sent(email)

  [
    to: user.email,
    subject: ~r/\bHello\b/i,
    text_body: &(String.contains(&1, user.name)),
  ]
  |> assert_email_sent()
  ```
  """
  @spec assert_email_sent(matches :: Enumerable.t, options :: Keyword.t) :: no_return | true
  def assert_email_sent(matches, options \\ []) do
    timeout = Keyword.get(options, :timeout, 10)
    failure_message = Keyword.get(options, :failure_message)
    do_assert_email_sent(matches, timeout, failure_message)
    true
  end

  @spec assert_no_email_sent(options :: Keyword.t) :: no_return | false
  def assert_no_email_sent(options \\ []) do
    timeout = Keyword.get(options, :timeout, 10)
    failure_message = Keyword.get(options, :failure_message)
    refute_receive({__MODULE__, _email}, timeout, failure_message)
  end

  @doc ~S"""
  An alias to assert_no_email_sent/1
  """
  def refute_email_sent(options \\ []) do
    assert_no_email_sent(options)
  end
end
