defmodule FactEngine.CLI do
  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv, strict: [input: :string, output: :string])

    case parse do
      {[input: x, output: y], _, _} -> {x, y}
      {[output: y, input: x], _, _} -> {x, y}
      _ -> :parseError
    end
  end

  def process(:parseError) do
    IO.puts("""
    usage: factengine --input <path_to_input_file> --output <path_to_output_file>
    """)

    System.halt(0)
  end

  def process({input, output}) do
    input
    |> FactEngine.Reader.read_file()
    |> FactEngine.eval_file(%{}, [])
    |> write_responses(output)
  end

  def write_responses(responses, output) do
    {:ok, file} = File.open(output, [:write])

    Enum.each(responses, fn x ->
      IO.puts(file, "---")
      format_response(x, file)
    end)
  end

  def format_response(response, output) when is_list(response) do
    Enum.each(response, fn x -> format_response(x, output) end)
  end

  def format_response(response, output) when is_map(response) do
    keys = Map.keys(response)
    Enum.each(keys, fn x -> IO.write(output, [x, ":  ", response[x], "  "]) end)
    IO.puts(output, "")
  end

  def format_response(response, output) do
    IO.puts(output, inspect(response))
  end
end
