class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :strava_id, null: false
      t.string :access_token, null: false
      t.string :refresh_token, null: false
      t.integer :token_expires_at, null: false
      t.string :name
      t.string :avatar_url

      t.timestamps
    end

    add_index :users, :strava_id, unique: true
  end
end
