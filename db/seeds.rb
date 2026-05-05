account = Account.find_or_create_by!(name: "Holden Architecture")

User.find_or_create_by!(email_address: "scott@holdenarchitecture.com") do |u|
  u.password = "password"
  u.account = account
end

opp1 = account.opportunities.find_or_create_by!(name: "Government Roofing Contracts") do |o|
  o.description = "Industrial and government roofing projects in Louisiana"
  o.criteria_text = "Looking for government and institutional roofing contracts near Baton Rouge, Louisiana. Minimum project size $200k. Target schools, government buildings, and municipal facilities. No residential."
  o.status = :active
end

opp2 = account.opportunities.find_or_create_by!(name: "Car Wash Facility Buildouts") do |o|
  o.description = "New construction and renovation for growing car wash chains"
  o.criteria_text = "New construction and major renovation projects for car wash businesses expanding in Louisiana and surrounding states. Looking for prototype design and multi-unit rollout opportunities."
  o.status = :active
end

opp1.sources.find_or_create_by!(name: "DOTD Public Bid Listings") do |s|
  s.url = "https://www.dotd.la.gov/inside_LaDOTD/Divisions/Engineering/ProjectBid/Pages/Bid-Letting-Advertisements.aspx"
  s.description = "Louisiana DOTD public bid advertisements"
  s.notes = "Check for new listings since last scan. Look for roofing-related projects."
  s.scan_frequency_days = 7
  s.status = :active
end

opp1.sources.find_or_create_by!(name: "LA State Purchasing Portal") do |s|
  s.url = "https://wwwcfprd.doa.louisiana.gov/OSP/LaPAC/pubMain.cfm"
  s.description = "Louisiana state purchasing and procurement portal"
  s.notes = "Search for roofing and construction contracts."
  s.scan_frequency_days = 3
  s.status = :active
end

opp1.leads.find_or_create_by!(title: "Baker High School Roof Replacement") do |l|
  l.description = "Full roof replacement on main building and gymnasium."
  l.status = :tracking
  l.client_name = "East Baton Rouge Parish School System"
  l.contact_name = "Mike Thibodaux"
  l.contact_email = "mthibodaux@ebrpss.k12.la.us"
  l.deadline = 3.months.from_now.to_date
  l.estimated_budget_cents = 85_000_000
  l.priority = :high
end

opp1.leads.find_or_create_by!(title: "Baton Rouge Police Dept HQ Exterior Renovation") do |l|
  l.description = "Exterior renovation including roof repairs and facade work."
  l.status = :new_lead
  l.client_name = "City of Baton Rouge"
  l.deadline = 6.weeks.from_now.to_date
  l.priority = :medium
end

opp2.leads.find_or_create_by!(title: "WhiteWave Car Wash — 5 Location Rollout") do |l|
  l.description = "Prototype design and construction documents for a 5-location rollout across Louisiana."
  l.status = :proposal_sent
  l.client_name = "WhiteWave Car Wash"
  l.contact_name = "Dana Fontenot"
  l.contact_email = "dana@whitewavecarwash.com"
  l.estimated_budget_cents = 275_000_000
  l.priority = :urgent
end

puts "Seeded: #{Account.count} account, #{User.count} user, #{Opportunity.count} opportunities, #{Source.count} sources, #{Lead.count} leads"
