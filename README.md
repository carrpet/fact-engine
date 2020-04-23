# FactEngine

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `fact_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fact_engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/fact_engine](https://hexdocs.pm/fact_engine).

## Running

You need an Elixir and mix environment to run this app.
Once you have installed both of those, unpack the tarball
into a local directory.  In the root of that directory, you 
can run the application with mix by typing

''' mix run -e 'FactEngine.CLI.run(["--input", "<input_file_path>", "--output", "<output_file_path>"])' '''

Note that the input and output flags are required.
