defmodule FactEngine.CLI do

    def run(argv) do
        argv
            |> parse_args
            |> process
    end

    def parse_args(argv) do
        parse = OptionParser.parse(argv, strict: [input: :string, output: :string])
        case parse do
            {[input: x, output: y], _ , _ } -> {x, y}
            {[output: y, input: x], _ , _ } -> {x, y}
            _                               -> :parseError
        end
    end

    def process(:parseError) do
        IO.puts """
        usage: factengine --input <path_to_input_file> --output <path_to_output_file>
        """
        System.halt(0)
    end

    def process({input,output}) do
        input
           |> FactEngine.Reader.read_file
           |> FactEngine.eval_file
           |> write_responses(output)
    end

    def write_responses(factMap,output) do
        {:ok, file} = File.open(output, [:write])
        %{responses: respList} = factMap 
        Enum.each(respList, fn x -> IO.puts(file,"---"); IO.puts(file,x) end)
    end
end