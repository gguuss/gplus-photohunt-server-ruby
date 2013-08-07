class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :google_user_id
      t.string :google_display_name
      t.string :google_public_profile_url
      t.string :google_public_profile_photo_url
      t.string :google_access_token
      t.string :google_refresh_token
      t.integer :google_expires_in
      t.integer :google_expires_at, limit: 8
    end
    add_index :users, :email
    add_index :users, :google_user_id
    add_index :users, :google_display_name
    add_index :users, :google_access_token
  end
end
