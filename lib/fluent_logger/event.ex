defexception FluentLogger.ConnectionError, host: nil, port: nil do
  def message(exception) do
    "cannot connect to #{exception.host}:#{exception.port}"
  end
end

defmodule FluentLogger.Event do
  use GenEvent.Behaviour

  defrecordp :state, [:tag, :host, :port, :socket]

  def init({tag, host, port}) do
    { :ok, socket } = :gen_tcp.connect(String.to_char_list!(host), port, [:binary, { :packet, 0 }])
    { :ok, state(tag: tag, host: host, port: port, socket: socket) }
  end

  def handle_event({ tag, data }, state() = s) do
    content = make_content(tag, data, s)
    send(content, s)
  end

  defp make_content(tag, data, state(tag: top_tag)) do
    { msec, sec, _ } = :erlang.now
    tag = make_tag(top_tag, tag)
    content = [tag, msec * 1000000 + sec, data]
    MessagePack.pack(content)
  end

  defp make_tag(top_tag, tag) do
    tag = tag || ""
    if top_tag, do: "#{top_tag}.#{tag}", else: tag
  end

  defp send(content, state(socket: socket, host: host, port: port) = s) do
    case :gen_tcp.send(socket, content) do
      :ok -> { :ok, s }
      _ -> raise FluentLogger.ConnectionError, host: host, port: port
    end
  end

  def terminate(_reason, state(socket: socket)) do
    :gen_tcp.close(socket)
  end
end
