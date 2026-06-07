class AddEffectiveDatesToProjectAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :project_allocations, :start_date, :date
    add_column :project_allocations, :end_date, :date
  end
end
