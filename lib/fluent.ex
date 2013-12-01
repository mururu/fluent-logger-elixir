defmodule Fluent do
  def add(ref, tag, options // []) do
    host = options[:host] || "localhost"
    port = options[:port] || 24224

    :gen_event.add_handler(ref, Fluent.Event, { tag, host, port })
  end

  def post(ref, tag, data) do
    :gen_event.notify(ref, { tag, data })
  end
end
