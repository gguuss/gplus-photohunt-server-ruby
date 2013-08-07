class CreateDirectedUserToUserEdges < ActiveRecord::Migration
  def change
    create_table :directed_user_to_user_edges do |t|
      t.integer :owner_user_id
      t.integer :friend_user_id
    end
    add_index :directed_user_to_user_edges, :owner_user_id
    add_index :directed_user_to_user_edges, :friend_user_id
  end
end
