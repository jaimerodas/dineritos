module GraphsHelper
  def percentage_graph_from(report)
    tag.div class: "graph-report" do
      report.each do |account|
        concat tag.div(
          tag.span(graph_account_title_from(account)),
          class: "graph-account #{cycle(
            "it-1", "it-2", "it-3", "it-4", "it-5", "it-6", "it-7",
            "it-8", "it-9", "it-0", name: "graph"
          )}",
          style: "--percent: #{formatted_percentage(account.percent)}"
        )
      end
    end
  end

  private

  def graph_account_title_from(row)
    "#{row.name} - #{formatted_percentage(row.percent)}"
  end

  def formatted_percentage(percent)
    "#{(percent * 100).round(2)}%"
  end
end
