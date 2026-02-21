class AddQrlTxHashToStatuses < ActiveRecord::Migration[7.0]  # Adjust version to your Mastodon (usually 6.1 or 7.0)
  def change
    add_column :statuses, :qrl_tx_hash, :string, default: nil
  end
end
