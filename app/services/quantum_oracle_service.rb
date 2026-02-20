# app/services/quantum_oracle_service.rb
class QuantumOracleService
  include HTTParty
  base_uri ENV['QUANTUM_ORACLE_URL']  # Uses the env var

  def self.call(mode, params = {})
    response = post('', body: { mode: mode, params: params }.to_json, headers: { 'Content-Type' => 'application/json' })
    if response.success?
      JSON.parse(response.body)
    else
      Rails.logger.error("Quantum oracle failed: #{response.code} - #{response.body}")
      { error: 'Fallback to classical mode' }  # Or nil for graceful failure
    end
  end
end
