defmodule Haytni.Migration do
  @moduledoc ~S"""
  Regroup various helper functions specifically used by migrations
  """

  @doc ~S"""
  Helper for migrations to choose the best type for a case insensitive string like email addresses
  based on the current database.

  Only handles PostgreSQL for now, by returning `:citext` instead of `:string` by default and try
  to install the citext extension if it was not already done.
  """
  @spec case_insensitive_string_type() :: atom
  def case_insensitive_string_type do
    case Ecto.Migration.repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        Ecto.Migration.execute("CREATE EXTENSION IF NOT EXISTS citext")
        :citext
      #Ecto.Adapters.MyXQL ->
      #Ecto.Adapters.MySQL -> # old versions of Ecto
        # can't define COLLATE in migration?
        #:string
      _ ->
        :string
    end
  end
end
