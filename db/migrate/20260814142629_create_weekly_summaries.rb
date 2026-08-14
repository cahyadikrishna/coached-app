class CreateWeeklySummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :weekly_summaries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.column :metrics, metrics_column_type
      t.text :content

      t.timestamps
    end

    add_index :weekly_summaries, [ :user_id, :start_date, :end_date ]
  end

  private

  def metrics_column_type
    connection.adapter_name == "PostgreSQL" ? :jsonb : :json
  end
end
