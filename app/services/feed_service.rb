def statuses
  # Existing logic to get candidate statuses
  candidate_statuses = from_redis || from_database  # Adjust to your Mastodon version

  # Quantum re-ranking
  if ENV['QUANTUM_ORACLE_URL'].present?
    payload = {
      user_id: @account.id,
      posts: candidate_statuses.first(50).map do |status|  # Cap to avoid huge payloads
        {
          id: status.id,
          content: status.text.truncate(280),
          likes: status.favourites_count,
          boosts: status.reblogs_count,
          timestamp: status.created_at.to_i
        }
      end
    }

    result = QuantumOracleService.call("vqe_qaoa", payload)

    if result && result['ranked'].is_a?(Array) && result['ranked'].any?
      ranked_statuses = result['ranked'].map do |ranked_id|
        candidate_statuses.find { |s| s.id.to_s == ranked_id.to_s }
      end.compact

      if ranked_statuses.any?
        candidate_statuses = ranked_statuses
        Rails.logger.info("Quantum feed ranking applied for user #{@account.id} (#{candidate_statuses.count} posts)")
      end
    else
      Rails.logger.warn("Quantum oracle returned invalid/no ranking; using default order")
    end
  end

  candidate_statuses
end
