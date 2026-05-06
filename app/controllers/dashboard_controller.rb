class DashboardController < ApplicationController
  def index
    @opportunities = current_account.opportunities.active.ordered
    @pending_review_count = PotentialLead.joins(source: :opportunity)
                                         .where(opportunities: { account: current_account })
                                         .pending
                                         .count
    @leads_by_status = current_account.opportunities
                                      .joins(:leads)
                                      .where(leads: { active: true })
                                      .group("leads.status")
                                      .count
    @upcoming_deadlines = Lead.joins(:opportunity)
                              .where(opportunities: { account: current_account })
                              .active
                              .where("deadline >= ? AND deadline <= ?", Date.current, 30.days.from_now)
                              .by_deadline
                              .limit(5)
    @sources_needing_attention = Source.joins(:opportunity)
                                       .where(opportunities: { account: current_account })
                                       .where("sources.consecutive_failure_count > 0 OR sources.status = ?", "paused")
                                       .order(consecutive_failure_count: :desc)
                                       .limit(10)
  end
end
