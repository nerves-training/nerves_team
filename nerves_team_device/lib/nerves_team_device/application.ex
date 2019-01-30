defmodule NervesTeamDevice.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesTeamDevice.Supervisor]
    children =
      [
        # Children for all targets
        # Starts a worker by calling: NervesTeamDevice.Worker.start_link(arg)
        # {NervesTeamDevice.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: NervesTeamDevice.Worker.start_link(arg)
      # {NervesTeamDevice.Worker, arg},
    ]
  end

  def children(_target) do
    {:ok, engine} = NervesKey.PKCS11.load_engine()
    {:ok, i2c} = ATECC508A.Transport.I2C.init([])

    cert =
      NervesKey.device_cert(i2c, :aux)
      |> X509.Certificate.to_der()

    signer_cert =
      NervesKey.signer_cert(i2c, :aux)
      |> X509.Certificate.to_der()

    key = NervesKey.PKCS11.private_key(engine, i2c: 1)
    cacerts = [signer_cert | NervesHub.Certificate.ca_certs()]

    [
      {NervesHub.Supervisor, [key: key, cert: cert, cacerts: cacerts]}
    ]
  end

  def target() do
    Application.get_env(:nerves_team_device, :target)
  end
end
