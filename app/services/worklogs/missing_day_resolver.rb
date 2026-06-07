module Worklogs
  # PROTOTYPE STAND-IN. Epico ALREADY computes missing/weekend/holiday/leave days
  # for its timesheet. This service exists only so the standalone prototype can run
  # end-to-end on its own DB and feed the genuinely-new parts (activity fetch + AI
  # draft). At port time into Epico this is DROPPED — we consume Epico's existing
  # missing-days data instead of recomputing it.
  #
  # Classifies every day of a (user, project, month) into one status: which days
  # genuinely need a worklog vs. days to never nag about (weekend / holiday /
  # approved leave / outside the allocation window / future / today / logged).
  #
  # The "missing" window is bounded by the allocation effective dates, the
  # project's start/end, and never extends into today or the future.
  #
  # Batch-loads holidays, leaves, and worklogs up front to avoid N+1 queries.
  #
  #   Worklogs::MissingDayResolver.call(user:, project:, year: 2026, month: 6)
  #   # => [#<Day date=2026-06-01 status=:logged ...>, ...]
  class MissingDayResolver
    Day = Data.define(:date, :status, :metadata)

    STATUSES = %i[weekend holiday unallocated leave logged future pending missing].freeze

    def self.call(user:, project:, year:, month:, today: Date.current)
      new(user:, project:, year:, month:, today:).call
    end

    def initialize(user:, project:, year:, month:, today: Date.current)
      @user = user
      @project = project
      @today = today
      @first = Date.new(year, month, 1)
      @last = @first.end_of_month
    end

    def call
      (@first..@last).map { |date| classify(date) }
    end

    private

    def classify(date)
      if weekend?(date)
        day(date, :weekend)
      elsif (holiday = holidays[date])
        day(date, :holiday, name: holiday.name)
      elsif !within_window?(date)
        day(date, :unallocated)
      elsif full_day_leave?(date)
        day(date, :leave, leave_type: "full_day")
      elsif (log = worklogs[date])
        day(date, :logged, worklog_id: log.id, hours: log.hours)
      elsif date > @today
        day(date, :future)
      elsif date == @today
        day(date, :pending, half_day_leave: half_day_leave?(date))
      else
        day(date, :missing, half_day_leave: half_day_leave?(date))
      end
    end

    def day(date, status, **metadata)
      Day.new(date:, status:, metadata:)
    end

    def weekend?(date)
      date.saturday? || date.sunday?
    end

    # Was the user allocated to this project on this date, and is the project
    # itself active on it?
    def within_window?(date)
      return false unless allocation&.effective_on?(date)
      return false if @project.start_date && date < @project.start_date
      return false if @project.end_date && date > @project.end_date

      true
    end

    def allocation
      @allocation ||= @user.project_allocations.find_by(project: @project)
    end

    def holidays
      @holidays ||= Holiday.where(holiday_date: @first..@last).index_by(&:holiday_date)
    end

    def leaves
      @leaves ||= @user.leaves.approved.where(leave_date: @first..@last).group_by(&:leave_date)
    end

    def full_day_leave?(date)
      Array(leaves[date]).any?(&:full_day?)
    end

    def half_day_leave?(date)
      Array(leaves[date]).any?(&:half_day?)
    end

    def worklogs
      @worklogs ||= @user.worklogs
                         .where(project: @project, work_date: @first..@last)
                         .index_by(&:work_date)
    end
  end
end
