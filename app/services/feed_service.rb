def statuses
  # Existing logic to get candidate statuses
  candidate_statuses = from_redis || from_database  # Adjust based on Mastodon version

  # Quantum re-ranking (optional)
  if ENV['QUANTUM_ORACLE_URL'].present?
    payload = {
      user_id: @account.id,
      posts: candidate_statuses.first(50).map do |status|
        {
          id: status.id,
          content: status.text.truncate(280),
          likes: status.favourites_count,
          boosts: status.reblogs_count,
          timestamp: status.created_at.to_i
        }
      end
    }

    cache_key = "quantum_feed_rank/#{@account.id}/#{candidate_statuses.map(&:id).sort.join(',')[0..100]}"
    result = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      QuantumOracleService.call("vqe_qaoa", payload)
    end

    if result && result['ranked'].is_a?(Array) && result['ranked'].any?
      ranked_statuses = result['ranked'].map do |ranked_id|
        candidate_statuses.find { |s| s.id.to_s == ranked_id.to_s }
      end.compact

      if ranked_statuses.any?
        candidate_statuses = ranked_statuses
        Rails.logger.info("Quantum feed ranking applied for user #{@account.id} (#{candidate_statuses.count} posts)")
      end
    else
      Rails.logger.warn("Quantum oracle returned invalid/empty ranking; using default order")
    end
  end

  candidate_statuses
end
