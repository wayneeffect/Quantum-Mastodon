# app/services/feed_service.rb

# ... existing imports and class definition ...

def statuses
  # Existing logic to get candidate statuses (from Redis or DB)
  candidate_statuses = from_redis || from_database  # Adjust based on your Mastodon version

  # Quantum re-ranking (optional, fallback if fails)
  if ENV['QUANTUM_ORACLE_URL'].present?
    payload = {
      user_id: @account.id,
      posts: candidate_statuses.map do |status|
        {
          id: status.id,
          content: status.text.truncate(280),  # Short summary for payload size
          likes: status.favourites_count,
          boosts: status.reblogs_count,
          timestamp: status.created_at.to_i
        }
      end
    }

    result = QuantumOracleService.call("vqe_qaoa", payload)

    if result && result['ranked'].is_a?(Array) && result['ranked'].any?
      # Reorder candidates based on oracle's ranked IDs
      ranked_statuses = result['ranked'].map do |ranked_id|
        candidate_statuses.find { |s| s.id.to_s == ranked_id.to_s }
      end.compact

      candidate_statuses = ranked_statuses if ranked_statuses.any?
    else
      Rails.logger.warn("Quantum oracle failed for feed ranking; using default order")
    end
  end

  # Continue with existing return
  candidate_statuses
end

# ... rest of file ...
