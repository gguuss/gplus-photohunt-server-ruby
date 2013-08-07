class CreateThemes < ActiveRecord::Migration
  def change
    create_table :themes do |t|
      t.string :display_name
      t.date :created
      t.date :start
      t.integer :preview_photo_id
    end
    add_index :themes, :created
    add_index :themes, :start
  end
end
