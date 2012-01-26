class AddTimestampsToConsumerTokens < ActiveRecord::Migration
  def change
    add_column :consumer_tokens, :authorized_at, :timestamp
    add_column :consumer_tokens, :invalidated_at, :timestamp
    add_column :consumer_tokens, :expires_at, :timestamp
  end
end
