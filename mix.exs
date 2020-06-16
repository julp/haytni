defmodule Haytni.MixProject do
  use Mix.Project

  defp elixirc_paths(:test), do: ~W[lib test/support]
  defp elixirc_paths(_), do: ~W[lib]

  def project do
    [
      app: :haytni,
      docs: docs(),
      version: "0.6.0",
      elixir: "~> 1.9",
      compilers: ~W[phoenix gettext]a ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Haytni",
      source_url: "https://github.com/julp/haytni",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
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
      {:bcrypt_elixir, "~> 2.2"}, # implies erlang > 20
      #{:argon2_elixir, "~> 2.0"},
      #{:pbkdf2_elixir, "~> 1.0"},
      {:ecto_sql, "~> 3.4"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.14"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      # jason is "optional" to phoenix and bamboo
      {:jason, "~> 1.2"},
      {:bamboo, "~> 1.5"}, # required by plugins: confirmable, lockable, recoverable and invitable
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ecto_network, "~> 1.3", only: :test}, # required by plugin: trackable with PostgreSQL
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.10", only: :test},
      #{:myxql, ">= 0.0.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
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
      Plugins: [
        Haytni.AuthenticablePlugin,
        Haytni.ConfirmablePlugin,
        Haytni.LockablePlugin,
        Haytni.RecoverablePlugin,
        Haytni.RegisterablePlugin,
        Haytni.RememberablePlugin,
        Haytni.TrackablePlugin,
        Haytni.PasswordPolicyPlugin,
      ],
      Authenticable: [
        Haytni.AuthenticablePlugin,
        Haytni.AuthenticablePlugin.Config,
      ],
      Confirmable: [
        Haytni.ConfirmablePlugin,
        Haytni.ConfirmablePlugin.Config,
        Haytni.ConfirmableEmail,
      ],
      Lockable: [
        Haytni.LockablePlugin,
        Haytni.LockablePlugin.Config,
        Haytni.LockableEmail,
      ],
      Recoverable: [
        Haytni.RecoverablePlugin,
        Haytni.RecoverablePlugin.Config,
        Haytni.Recoverable.PasswordChange,
        Haytni.RecoverableEmail,
      ],
      Registerable: [
        Haytni.RegisterablePlugin,
        Haytni.RegisterablePlugin.Config,
      ],
      PasswordPolicy: [
        Haytni.PasswordPolicyPlugin,
        Haytni.PasswordPolicyPlugin.Class,
        Haytni.PasswordPolicyPlugin.Config,
      ],
      Rememberable: [
        Haytni.RememberablePlugin,
        Haytni.RememberablePlugin.Config,
      ],
      Trackable: [
        Haytni.TrackablePlugin,
        Haytni.TrackablePlugin.Config,
      ],
      Helpers: [
        Haytni.Params,
        Haytni.Helpers,
        HaytniWeb.Helpers,
        HaytniWeb.Shared,
      ],
    ]
  end
end
