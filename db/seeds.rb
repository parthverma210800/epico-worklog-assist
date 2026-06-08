# Seed data for the Smart Worklog Assist prototype.
# One engineer allocated 8h/day to "Mocingbird" with a few filled worklogs (Jun 1-4).
# Leave/holiday classification is Epico's responsibility, not this feature's.
# Idempotent: clears and recreates.
#
# Run with: bin/rails db:seed

puts "Clearing existing data..."
[WorklogDraft, Worklog, ProjectRepository, ProjectAllocation,
 IntegrationConnection].each(&:delete_all)
User.delete_all
Project.delete_all

puts "Creating user + project..."
employee1 = User.create!(name: "Employee1", email: "employee1@example.com")

mocingbird = Project.create!(
  name: "Mocingbird",
  description: "Ongoing medical education platform for providers",
  status: "active",
  project_type: "delivery",
  start_date: Date.new(2023, 10, 1),
  end_date: Date.new(2026, 12, 31)
)

puts "Allocating Employee1 to Mocingbird (8h/day, since Jan 2026)..."
ProjectAllocation.create!(user: employee1, project: mocingbird, daily_hours: 8,
                          active: true, start_date: Date.new(2026, 1, 1))

puts "Mapping GitHub repos -> Mocingbird..."
%w[org/epp org/mocingbird].each do |repo|
  ProjectRepository.create!(project: mocingbird, provider: "github", repo_full_name: repo)
end

puts "Creating existing worklogs (Jun 1-4, 2026)..."
{
  Date.new(2026, 6, 1) => "Story -> sc-183706\n1. cut branch for OR SW smoke-test bug fixes\n2. inventory the three reported bugs\n3. fix Bug #1 ethics sub_category",
  Date.new(2026, 6, 2) => "Story -> sc-184753\n1. audit custom_calculation methods across state-license files\n2. identify dispatch/flag-branching patterns\n3. tally schema-fit vs schema-extension methods",
  Date.new(2026, 6, 3) => "Story -> sc-183706\n1. capture proof of Bug #3 placeholder leak\n2. trace 500 NoMethodError at or.rb:265\nStory -> sc-169861\n1. review FL DO state-license rules diff",
  Date.new(2026, 6, 4) => "Story -> sc-169861\n1. point PR #11832 base to staging-next\nStory -> sc-208220\n1. review 14 Dependabot alerts\n2. bump nokogiri/net-imap/faraday, commit & push"
}.each do |date, description|
  Worklog.create!(user: employee1, project: mocingbird, work_date: date, description: description, hours: 8)
end
# Jun 5 onward intentionally left unlogged (drafted via Auto Draft from PR).

puts "Done. Users=#{User.count} Projects=#{Project.count} " \
     "Worklogs=#{Worklog.count} Repos=#{ProjectRepository.count}"
