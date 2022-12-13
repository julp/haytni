defmodule Haytni.Mailer.TaskSupervisorStrategy do
  @moduledoc ~S"""
  TODO (doc)
  """
  use Haytni.Mailer.DeliveryStrategy

  @impl Haytni.Mailer.DeliveryStrategy
  def deliver(email = %Haytni.Mail{}, mailer, options) do
    Task.Supervisor.start_child(
      Keyword.get_lazy(options, :supervisor, &supervisor_name/0),
      fn ->
        email
        |> mailer.cast(mailer, options)
        |> mailer.send(mailer, options)
        |> case do
          :ok ->
            :ok
          {:error, error} ->
            raise error
        end
      end
    )
    # TODO: {:ok, pid()} | {:ok, pid(), info :: term()} | :ignore | {:error, {:already_started, pid()} | :max_children | term()}
    :ok
  end

  def supervisor_name do
    __MODULE__
  end
end
