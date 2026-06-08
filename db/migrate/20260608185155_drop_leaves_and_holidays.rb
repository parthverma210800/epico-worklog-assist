class DropLeavesAndHolidays < ActiveRecord::Migration[8.1]
  def up
    drop_table :leaves
    drop_table :holidays
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
