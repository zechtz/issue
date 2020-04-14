defmodule Issues.Cli do
  alias Issues.GithubIssues
  import Issues.GithubIssues, only: [print_table_for_columns: 2]

  @default_count 4

  @moduledoc """
  Handle the commandline parsing and the dispatch to
  the various functions that end up generating a
  table f the last n_issues in a github project
  """

  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  @doc """
  `argv` can be -h or --help which returns :help.

  Otherwise it is a github username, project name, and (optionally)
  the number of entries to format

  Return a tuple of `{user, project, count}` or `:help` if help was given
  """
  def parse_args(argv) do
    OptionParser.parse(argv, switches: [help: :boolean], aliases:  [h: :help])
    |> elem(1)
    |> args_to_internal_representation()
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
    System.halt(0)
  end

  def process({user, project,_count}) do
    GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_descending_order
  end

  def process({user, project,count}) do
    GithubIssues.fetch(user, project)
    |> decode_response
    |> sort_into_descending_order
    |> last(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def sort_into_descending_order(issues) do
    issues
    |> Enum.sort(fn(i1, i2) ->
      i1["created_at"] >= i2["created_at"]
    end)
  end

  defp decode_response({:ok, body}), do: body

  defp decode_response({:error, error}) do
    IO.puts "Error fetching Github: #{error["message"]}"
  end

  defp args_to_internal_representation([user, project, count]) do
    { user, project, String.to_integer(count) }
  end

  defp args_to_internal_representation([user, project]) do
    { user, project, @default_count }
  end

  defp args_to_internal_representation(_) do
    :help
  end

  defp last(list, count) do
    list
    |> Enum.take(count)
    |> Enum.reverse
  end
end
