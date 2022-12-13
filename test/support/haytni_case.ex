defmodule Haytni.Case do
  def haytni_common(options) do
    plugin = Keyword.get(options, :plugin)
    {email_quote, options} = if email = Keyword.get(options, :email) do
      {async, rest} = Keyword.pop(options, :async, false)
      if async do
        IO.warn(":async option can't be true when :email is also present")
      end
      {
        case email do
          :swoosh ->
            quote do
              @mailer HaytniTest.SwooshMailer
              @adapter Haytni.Mailer.SwooshAdapter
            end
          value when value in [:bamboo, true] ->
            quote do
              use Bamboo.Test, shared: true
              @adapter Haytni.Mailer.BambooAdapter
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
      @mailer HaytniTest.BambooMailer
      @router HaytniTestWeb.Router
      @endpoint HaytniTestWeb.Endpoint

      # here to override the module attributes above
      unquote(email_quote)

      @moduletag plugin: @plugin
    end

    {options, quoted}
  end
end
