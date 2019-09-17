defmodule Haytni.MixProject do
  use Mix.Project

  def project do
    [
      app: :haytni,
      docs: docs(),
      version: "0.0.2",
      elixir: "~> 1.6",
      compilers: ~W[phoenix gettext]a ++ Mix.compilers(),
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
      {:bcrypt_elixir, "~> 2.0"}, # implies erlang > 20
      #{:argon2_elixir, "~> 2.0"},
      #{:pbkdf2_elixir, "~> 1.0"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix, "~> 1.4"},
      {:phoenix_html, "~> 2.11"},
      {:ecto_network, "~> 1.0.0"}, # required by plugin: trackable
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:bamboo, "~> 1.3"} # required by plugins: confirmable, lockable and recoverable
    ]
  end

  defp description() do
    "A flexible authentication (and more) solution for Phoenix"
  end

  defp package() do
    [
      files: ["lib", "priv", "mix.exs", "README*", "CHANGELOG*"],
      licenses: ["BSD"],
      links: %{"GitHub" => "https://github.com/julp/haytni"}
    ]
  end

  defp docs do
    [
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules()
    ]
  end

  defp extras do
    Path.wildcard("guides/**/*.md")
  end

  defp groups_for_extras do
    [
      Installation: "guides/installation.md",
      "How to": ~R"guides/howto/.*\.md",
    ]
  end

  defp groups_for_modules do
    [
      #Haytni
      #Haytni.Mail
      #Haytni.Plugin
      #Haytni.Gettext
      #Haytni.Token
      #Haytni.Users
      #HaytniWeb.Shared
      Plugins: [
        Haytni.AuthenticablePlugin,
        Haytni.ConfirmablePlugin,
        Haytni.LockablePlugin,
        Haytni.RecoverablePlugin,
        Haytni.RegisterablePlugin,
        Haytni.RememberablePlugin,
      ],
      Plugs: [
        Haytni.CurrentUserPlug,
        Haytni.ViewAndLayoutPlug,
      ],
      Authenticable: [
        Haytni.AuthenticablePlugin,
        Haytni.Session,
      ],
      Confirmable: [
        Haytni.ConfirmablePlugin,
        Haytni.ConfirmableEmail,
        Haytni.Confirmation,
      ],
      Lockable: [
        Haytni.LockablePlugin,
        Haytni.LockableEmail,
        Haytni.Unlockable.Request,
      ],
      Recoverable: [
        Haytni.RecoverablePlugin,
        Haytni.Recoverable.PasswordChange,
        Haytni.Recoverable.ResetRequest,
        Haytni.RecoverableEmail,
      ],
      Registerable: [
        Haytni.RegisterablePlugin,
      ],
      Rememberable: [
        Haytni.RememberablePlugin,
      ],
    ]
  end
end
