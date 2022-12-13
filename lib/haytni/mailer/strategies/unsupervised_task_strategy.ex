defmodule Haytni.Mailer.UnsupervisedTaskStrategy do
  @moduledoc ~S"""
  This is the strategy to send email asynchronously (the user doesn't have to wait) but without any supervision:
  an error will not be reported back and in case of failure, there won't be any new attempt to try to re-send it.
  """
  use Haytni.Mailer.DeliveryStrategy

  @impl Haytni.Mailer.DeliveryStrategy
  def deliver(email = %Haytni.Mail{}, mailer, options) do
    Task.start(
      fn ->
        email
        |> mailer.cast(mailer, options)
        |> mailer.send(mailer, options)
      end
    )
    # TODO: Task.start/1 returns {:ok, pid()}
    :ok
  end
end
