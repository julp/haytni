defmodule Haytni.Case do
  @application_pid_key :shared_test_process
  def haytni_common(options) do
    plugin = Keyword.get(options, :plugin)
    {email_quote, options} =
      if Keyword.get(options, :email) do
        {async, rest} = Keyword.pop(options, :async, false)
        if async do
          IO.warn(":async option can't be true when :email is also present")
        end
        {
          quote do
            import Haytni.Mailer.TestAdapter

            @adapter Haytni.Mailer.TestAdapter

            setup do
              Application.put_env(:haytni, unquote(@application_pid_key), self())
              ExUnit.Callbacks.on_exit(
                fn ->
                  Application.delete_env(:haytni, unquote(@application_pid_key))
                end
              )
            end
          end,
          rest
        }
      else
        {[], options}
      end

    quoted = quote do
      @plugin unquote(plugin)
      @repo HaytniTest.Repo
      @stack HaytniTestWeb.Haytni
      @mailer HaytniTest.TestMailer
      @router HaytniTestWeb.Router
      @endpoint HaytniTestWeb.Endpoint

      # here to override the module attributes above
      unquote(email_quote)

      @moduletag plugin: @plugin
    end

    {options, quoted}
  end
end
