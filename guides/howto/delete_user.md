# How to delete a user

Haytni does not currently assume user deletion (account removal) because everyone might want to do it in different ways:

* delay it to give some time to the user to think about it and cancel it if wished
* confirm the action
* do some kind of soft-deletion instead
* remove extra data, even non-SQL
* ...

So, you have to do it by yourself but it's not difficult. Here are some guidelines:

First, add a route in your router to your own controller, called here YourAppWeb.UserController (we will write it next):

```elixir
# lib/your_app_web/router.ex
resources "/users", YourAppWeb.UserController, only: ~W[delete]a
# or, if you prefer to use the delete helper/macro:
#delete "/users", YourAppWeb.UserController, :delete
```

Secondly, write the controller YourAppWeb.UserController with this delete action:

```elixir
# lib/your_app_web/controllers/user_controller.ex
defmodule YourAppWeb.UserController do
  use YourAppWeb, :controller

  def delete(conn, _params) do
    if user = conn.assigns[:current_user] do
      Accounts.delete_user!(user)
      conn
      |> Haytni.logout(YourAppWeb.Haytni) # force logout in the process
      |> put_flash(:info, "Your account has been successfully deleted")
    else
      conn
    end
    |> redirect(to: "/")
    |> halt()
  end
end
```

Lastly, in the context to manage your users, add a function to delete users:

```elixir
# lib/your_app/accounts.ex
defmodule YourApp.Accounts do
  import Ecto.Query, warn: false
  alias YourApp.Repo

  # ...

  def delete_user!(user) do
    user
    |> Repo.delete!()
  end
end
```

Knowing that you can put whatever logic you want in this YourApp.Accounts.delete_user!/1: you can, of course, replace this DELETE query by an UPDATE, do some extra operations like deleting files and so on.

Note: don't forget to adapt `YourApp`, `YourAppWeb` and `Accounts` parts in module names to the modules you actually use
