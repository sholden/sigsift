module ApplicationHelper
  STATUS_COLORS = {
    "new" => "bg-gray-100 text-gray-700",
    "tracking" => "bg-blue-100 text-blue-700",
    "proposal_sent" => "bg-yellow-100 text-yellow-700",
    "won" => "bg-green-100 text-green-700",
    "lost" => "bg-red-100 text-red-700"
  }.freeze

  PRIORITY_COLORS = {
    "low" => "bg-gray-100 text-gray-600",
    "medium" => "bg-blue-100 text-blue-600",
    "high" => "bg-orange-100 text-orange-700",
    "urgent" => "bg-red-100 text-red-700"
  }.freeze

  def lead_status_badge(status)
    css = STATUS_COLORS[status.to_s] || "bg-gray-100 text-gray-700"
    content_tag(:span, status.to_s.humanize.gsub("New lead", "New"), class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end

  def lead_priority_badge(priority)
    return "" if priority.blank?
    css = PRIORITY_COLORS[priority.to_s] || "bg-gray-100 text-gray-600"
    content_tag(:span, priority.to_s.capitalize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end
end
