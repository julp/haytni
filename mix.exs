defmodule Haytni.MixProject do
  use Mix.Project

  def project do
    [
      app: :haytni,
      version: "0.0.1",
      elixir: "~> 1.6",
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Haytni",
      source_url: "https://github.com/julp/haytni"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, ">= 0.0.0"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.2"},
      {:pbkdf2_elixir, "~> 0.12"},
      (
        if :erlang.system_info(:otp_release) |> to_string |> String.to_integer > 19 do
          {:bcrypt_elixir, "~> 1.0"}
        else
          {:bcrypt_elixir, "~> 0.12"}
        end
      ),
      {:ecto, "~> 2.0"},
      {:phoenix, "~> 1.3"},
      #{:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.11"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:bamboo, "~> 0.8"} # required by plugins: confirmable, lockable and recoverable
    ]
  end

  defp description() do
    "A flexible authentication (and more) solution for Phoenix"
  end

  defp package() do
    [
      #name: "haytni",
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      licenses: ["BSD"],
      links: %{"GitHub" => "https://github.com/julp/haytni"}
    ]
  end
end