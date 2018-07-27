defmodule Haytni.Gettext do
  use Gettext, otp_app: :haytni

  defmacro dgettext(msgid) do
    quote do
      dgettext("haytni", unquote(msgid))
    end
  end
end
