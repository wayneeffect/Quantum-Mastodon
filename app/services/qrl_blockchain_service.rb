# app/services/qrl_blockchain_service.rb
require 'eth'

class QrlBlockchainService
  include HTTParty
  base_uri ENV['QRL_RPC_URL']

  def self.submit_transaction(event_type, data)
    # Prepare payload for QRL RPC or contract call
    payload = {
      event: event_type,  # e.g., "new_post"
      data: data,  # e.g., { post_id: 123, content_hash: Digest::SHA256.hexdigest(data[:content]) }
      timestamp: Time.now.to_i
    }

    # Example RPC call (for testnet; adapt for EVM contracts if using QRL 2.0 EVM)
    response = post('/transaction', body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
    if response.success?
      JSON.parse(response.body)  # Returns { tx_hash: "..." }
    else
      Rails.logger.error("QRL blockchain failed: #{response.code} - #{response.body}")
      nil  # Fallback
    end
  end

  def self.call_contract(method, args = {})
    # For EVM-compatible contracts on QRL 2.0
    # Use Eth gem to sign/call (placeholder; customize with your contract ABI)
    key = Eth::Key.new priv: ENV['QRL_PRIVATE_KEY']
    account = Eth::Address.new ENV['QRL_WALLET_ADDRESS']
    tx = Eth::Tx.new({
      to: ENV['QRL_CONTRACT_ADDRESS'],
      data: "method_signature_with_args",  # ABI-encode method + args
      gas: 21000, gas_price: 1 * Eth::Unit::GWEI, nonce: 0  # Adjust
    })
    tx.sign key
    # Send via RPC (post to /send_raw_transaction)
    response = post('/send_raw_transaction', body: { tx: tx.hex }.to_json)
    if response.success?
      JSON.parse(response.body)
    else
      nil
    end
  end
end
