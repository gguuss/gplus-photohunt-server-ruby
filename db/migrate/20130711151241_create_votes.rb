class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer :owner_user_id
      t.integer :photo_id
    end
    add_index :votes, :owner_user_id
    add_index :votes, :photo_id
  end
end
