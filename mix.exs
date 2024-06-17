defmodule Haytni.MixProject do
  use Mix.Project

  @version "0.7.0"

  defp elixirc_paths(:test), do: ~W[lib test/support]
  defp elixirc_paths(_), do: ~W[lib]

  def project do
    [
      app: :haytni,
      docs: docs(),
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: [plt_add_apps: ~W[mix ex_unit]a],
      name: "Haytni",
      source_url: "https://github.com/julp/haytni",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: ~W[logger]a,
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, "~> 0.20"},
      {:ecto_sql, "~> 3.7"},
      {:phoenix, "~> 1.6"},
      {:phoenix_view, "~> 1.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      # jason is "optional" to phoenix and bamboo
      {:jason, "~> 1.2"},
      {:dialyxir, "~> 1.0", only: ~W[dev test]a, runtime: false},
      {:ecto_network, "~> 1.3", only: :test}, # required by plugin: trackable with PostgreSQL
      {:excoveralls, "~> 0.14", only: :test},
      #{:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      #{:sobelow, "~> 0.10", only: :test},
      #{:myxql, ">= 0.0.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:phoenix_live_view, "~> 0.20"},
      {:floki, ">= 0.30.0", only: :test},
      {:expassword, "~> 0.2"},
      {:expassword_bcrypt, "~> 0.2", only: :test},
    ]
  end

  defp description do
    "A flexible authentication (and more) solution for Phoenix"
  end

  defp package do
    [
      files: ~W[lib priv mix.exs README* CHANGELOG*],
      licenses: ~W[BSD],
      links: %{"GitHub" => "https://github.com/julp/haytni"}
    ]
  end

  defp docs do
    [
      source_ref: @version,
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
      "How to": ~r"guides/howto/.*\.md",
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
        Haytni.InvitablePlugin,
        Haytni.LiveViewPlugin,
        Haytni.ClearSiteDataPlugin,
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
      Invitable: [
        Haytni.InvitablePlugin,
        Haytni.InvitablePlugin.Config,
        Haytni.InvitableEmail,
      ],
      LiveView: [
        Haytni.LiveViewPlugin,
        Haytni.LiveViewPlugin.Config,
      ],
      ClearSiteData: [
        Haytni.ClearSiteDataPlugin,
        Haytni.ClearSiteDataPlugin.Config,
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
