defexception Fluent.ConnectionError, host: nil, port: nil, reason: "" do
  def message(exception) do
    "cannot connect to #{exception.host}:#{exception.port} by #{exception.reason}"
  end
end

defmodule Fluent.Handler do
  use GenEvent.Behaviour

  defrecordp :state, [:tag, :host, :port, :socket]

  def init({tag, host, port}) do
    { :ok, host } = String.to_char_list(host)
    { :ok, socket } = :gen_tcp.connect(host, port, [:binary, { :packet, 0 }])
    { :ok, state(tag: tag, host: host, port: port, socket: socket) }
  end

  def handle_event({ tag, data }, state() = s) when is_list(data) do
    content = make_content(tag, {data}, s)
    send(content, s, 3)
  end

  defp make_content(tag, data, state(tag: top_tag)) do
    { msec, sec, _ } = :os.timestamp
    tag = make_tag(top_tag, tag)
    content = [tag, msec * 1000000 + sec, data]
    MessagePack.pack(content)
  end

  defp make_tag(top_tag, tag) do
    tag = tag || ""
    if top_tag, do: "#{top_tag}.#{tag}", else: tag
  end

  defp send(_content, state(host: host, port: port), 0) do
    raise Fluent.ConnectionError, host: host, port: port, reason: "retry limit"
  end

  defp send(content, state(socket: socket, host: host, port: port) = s, count) do
    case :gen_tcp.send(socket, content) do
      :ok ->
        { :ok, s }
      { :error, :closed } ->
        { :ok, socket } =:gen_tcp.connect(host, port, [:binary, { :packet, 0 }])
        send(content, state(s, socket: socket), count - 1)
      { :error, reason } ->
        raise Fluent.ConnectionError, host: host, port: port, reason: atom_to_binary(reason)
    end
  end

  def terminate(_reason, state(socket: socket)) do
    :gen_tcp.close(socket)
  end
end
