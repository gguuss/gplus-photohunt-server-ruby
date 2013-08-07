class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.integer :owner_user_id
      t.string :owner_display_name
      t.string :owner_profile_url
      t.string :owner_profile_photo
      t.integer :theme_id
      t.string :theme_display_name
      t.date :created
    end
    add_index :photos, :owner_user_id
    add_index :photos, :theme_id
    add_index :photos, :theme_display_name
  end
end
