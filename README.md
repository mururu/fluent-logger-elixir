# FluentLogger

A gen_event handler for fluent

```elixir
:gen_event.start({ :local, :your_logger })
Fluent.add(:your_logger, "myapp")
Fluent.post(:your_logger, "access", [status: 200, agent: "foo"])

# 2013-12-01 20:40:52 +0900 myapp.access: {"status":200,"agent":"foo"}
```
