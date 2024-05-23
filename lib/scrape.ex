defmodule Scrape do
  def do_it do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.get("https://diskanalyzer.com/wiztree-old-versions")

    {:ok, document} = Floki.parse_document(body)

    urls = get_urls(document)
    version_numbers = get_version_numbers(urls)
    dates = get_dates(document)

    %{urls: urls, dates: dates, version_numbers: version_numbers}

    urls
    |> Enum.with_index()
    |> Enum.map(fn {url, index} ->
      %{url: url, version_number: Enum.at(version_numbers, index), date: Enum.at(dates, index)}
    end)
  end

  defp get_urls(document) do
    document
    |> Floki.find("table > tbody > tr > td > a")
    |> Floki.attribute("href")
    |> Enum.filter(fn href -> String.contains?(href, "setup") end)
  end

  defp get_dates(document) do
    dates =
      document |> Floki.find("table > tbody > tr > td + td:fl-contains('/')") |> Floki.text()

    Regex.scan(~r/\d{4}\/\d{2}\/\d{2}/, dates)
    |> Enum.map(fn [date] -> date end)
  end

  defp get_version_numbers(urls) do
    Enum.map(urls, fn url ->
      Regex.run(~r/\d{1}_\d{2}/, url, capture: :first)
      |> hd()
      |> String.replace("_", ".")
    end)
  end
end
