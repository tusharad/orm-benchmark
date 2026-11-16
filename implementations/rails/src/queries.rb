require_relative 'models'

module Queries
  module_function

  # HQ01: Massive Entity Deserialization (10k Wide Rows)
  def hq01_massive_deserialization
    Flight.order(:flight_id).limit(10_000).to_a
  end

  # HQ02: Wide Multi-Join Composite Hydration (5k Joined Rows)
  def hq02_wide_multi_join
    sql = <<-SQL
      SELECT b.booking_id, b.booking_ref, b.email,
             p.passenger_id, p.first_name, p.last_name,
             bl.booking_leg_id, bl.leg_num,
             f.flight_id, f.flight_no, f.scheduled_departure, f.departure_airport, f.arrival_airport
      FROM postgres_air.booking b
      JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
      JOIN postgres_air.booking_leg bl ON b.booking_id = bl.booking_id
      JOIN postgres_air.flight f ON bl.flight_id = f.flight_id
      WHERE b.booking_id BETWEEN 100000 AND 105000
      LIMIT 5000
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ03: 4-Level Deep Entity Tree (Flight -> Legs -> Booking -> Pass)
  def hq03_deep_hierarchical_graph
    Flight.where(flight_id: 2000..2025)
          .includes(booking_legs: [:booking, :boarding_passes])
          .order(:flight_id)
          .to_a
  end

  # HQ04: Account Relationship Graph with Optional Sub-Entities
  def hq04_account_relationship_graph
    Account.where(account_id: 1000..1050)
           .includes(:frequent_flyer, :phones, bookings: :passengers)
           .order(:account_id)
           .to_a
  end

  # HQ05: Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)
  def hq05_route_financial_ledger(start_date = '2024-07-01', end_date = '2024-07-04')
    sql = <<-SQL
      SELECT f.flight_no,
             f.departure_airport,
             f.arrival_airport,
             ac.model AS aircraft_model,
             count(DISTINCT f.flight_id) AS total_flights,
             count(DISTINCT b.booking_id) AS total_bookings,
             count(p.passenger_id) AS total_passengers,
             coalesce(sum(b.price), 0.0)::float8 AS gross_revenue,
             round(avg(b.price), 2)::float8 AS avg_ticket_price
      FROM postgres_air.flight f
      JOIN postgres_air.aircraft ac ON f.aircraft_code = ac.code
      JOIN postgres_air.booking_leg bl ON f.flight_id = bl.flight_id
      JOIN postgres_air.booking b ON bl.booking_id = b.booking_id
      LEFT JOIN postgres_air.passenger p ON b.booking_id = p.booking_id
      WHERE f.scheduled_departure >= '#{start_date}'::timestamptz 
        AND f.scheduled_departure < '#{end_date}'::timestamptz
      GROUP BY f.flight_no, f.departure_airport, f.arrival_airport, ac.model
      ORDER BY gross_revenue DESC, total_passengers DESC
      LIMIT 100
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
  def hq06_hub_centrality_degree(start_date = '2024-06-01', end_date = '2024-07-01')
    sql = <<-SQL
      WITH flight_nodes AS (
          SELECT departure_airport AS hub,
                 arrival_airport AS spoke,
                 count(*)::int AS outbound_flights
          FROM postgres_air.flight
          WHERE scheduled_departure >= '#{start_date}'::timestamptz 
            AND scheduled_departure < '#{end_date}'::timestamptz
          GROUP BY departure_airport, arrival_airport
      ),
      hub_metrics AS (
          SELECT hub,
                 count(DISTINCT spoke)::int AS degree_out,
                 sum(outbound_flights)::bigint AS total_departures
          FROM flight_nodes
          GROUP BY hub
      ),
      ranked_hubs AS (
          SELECT hub,
                 degree_out,
                 total_departures,
                 dense_rank() OVER (ORDER BY total_departures DESC) AS departure_rank,
                 dense_rank() OVER (ORDER BY degree_out DESC) AS connectivity_rank
          FROM hub_metrics
      )
      SELECT hub, degree_out, total_departures, departure_rank, connectivity_rank
      FROM ranked_hubs
      WHERE departure_rank <= 20 OR connectivity_rank <= 20
      ORDER BY departure_rank ASC
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
  def hq07_at_capacity_loyalty_cross_check(start_date = '2024-07-01', end_date = '2024-07-04')
    sql = <<-SQL
      SELECT f.flight_id,
             f.flight_no,
             f.scheduled_departure,
             (SELECT count(*)::int FROM postgres_air.booking_leg bl WHERE bl.flight_id = f.flight_id) AS current_load,
             (SELECT avg(ff.award_points)::float8
              FROM postgres_air.booking_leg bl2
              JOIN postgres_air.passenger p ON bl2.booking_id = p.booking_id
              JOIN postgres_air.account a ON p.account_id = a.account_id
              JOIN postgres_air.frequent_flyer ff ON a.frequent_flyer_id = ff.frequent_flyer_id
              WHERE bl2.flight_id = f.flight_id) AS avg_vip_points
      FROM postgres_air.flight f
      WHERE f.scheduled_departure >= '#{start_date}'::timestamptz 
        AND f.scheduled_departure < '#{end_date}'::timestamptz
        AND (
            SELECT count(*) FROM postgres_air.booking_leg bl3 WHERE bl3.flight_id = f.flight_id
        ) > 20
      ORDER BY current_load DESC
      LIMIT 50
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ08: Recursive Multi-Hop Flight Connection Graph (1-3 Hops)
  def hq08_recursive_flight_path_search(origin = 'JFK', dest = 'ORD', start_date = '2024-07-05', end_date = '2024-07-06')
    sql = <<-SQL
      WITH RECURSIVE flight_itinerary AS (
          SELECT flight_id,
                 flight_no,
                 departure_airport,
                 arrival_airport,
                 scheduled_departure,
                 scheduled_arrival,
                 1 AS hops,
                 ARRAY[departure_airport, arrival_airport]::text[] AS route
          FROM postgres_air.flight
          WHERE departure_airport = '#{origin}'
            AND scheduled_departure >= '#{start_date}'::timestamptz 
            AND scheduled_departure < '#{end_date}'::timestamptz

          UNION ALL

          SELECT next_f.flight_id,
                 next_f.flight_no,
                 next_f.departure_airport,
                 next_f.arrival_airport,
                 next_f.scheduled_departure,
                 next_f.scheduled_arrival,
                 fi.hops + 1,
                 fi.route || next_f.arrival_airport::text
          FROM postgres_air.flight next_f
          JOIN flight_itinerary fi ON next_f.departure_airport = fi.arrival_airport
          WHERE next_f.scheduled_departure >= fi.scheduled_arrival + INTERVAL '1 hour'
            AND next_f.scheduled_departure <= fi.scheduled_arrival + INTERVAL '6 hours'
            AND fi.hops < 3
            AND NOT (next_f.arrival_airport = ANY(fi.route))
      )
      SELECT route, hops, scheduled_departure, scheduled_arrival
      FROM flight_itinerary
      WHERE arrival_airport = '#{dest}'
      ORDER BY hops ASC, scheduled_arrival ASC
      LIMIT 20
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ09: Multi-Window Statistical Delay Dispersion & Cascades
  def hq09_multi_window_delay_dispersion(airport = 'ORD', start_date = '2024-06-01', end_date = '2024-07-01')
    sql = <<-SQL
      SELECT flight_id,
             flight_no,
             scheduled_departure,
             actual_departure,
             coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)::float8 AS delay_minutes,
             avg(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
                 PARTITION BY departure_airport 
                 ORDER BY scheduled_departure 
                 ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
             )::float8 AS moving_avg_delay,
             stddev(coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)) / 60.0, 0.0)) OVER (
                 PARTITION BY departure_airport 
                 ORDER BY scheduled_departure 
                 ROWS BETWEEN 10 PRECEDING AND CURRENT ROW
             )::float8 AS stddev_delay,
             dense_rank() OVER (
                 PARTITION BY departure_airport 
                 ORDER BY coalesce(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure)), 0.0) DESC
             ) AS delay_severity_rank
      FROM postgres_air.flight
      WHERE departure_airport = '#{airport}'
        AND scheduled_departure >= '#{start_date}'::timestamptz 
        AND scheduled_departure < '#{end_date}'::timestamptz
      ORDER BY scheduled_departure ASC
      LIMIT 100
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end

  # HQ10: Keyset (Cursor) Pagination over Composite Key Under Load
  def hq10_keyset_pagination(cursor_time, cursor_id, limit = 50)
    Flight.where("scheduled_departure > :time OR (scheduled_departure = :time AND flight_id > :id)", time: cursor_time, id: cursor_id)
          .order(scheduled_departure: :asc, flight_id: :asc)
          .limit(limit)
          .to_a
  end

  # HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
  def hq11_dynamic_faceted_search(params)
    scope = Flight.joins(:aircraft).includes(:aircraft)
    scope = scope.where(departure_airport: params[:origins]) if params[:origins]&.any?
    scope = scope.where(arrival_airport: params[:destinations]) if params[:destinations]&.any?
    scope = scope.where("postgres_air.flight.scheduled_departure >= ?", params[:min_departure]) if params[:min_departure]
    scope = scope.where("postgres_air.flight.scheduled_departure <= ?", params[:max_departure]) if params[:max_departure]
    scope = scope.where("postgres_air.aircraft.class" => params[:aircraft_class]) if params[:aircraft_class]&.any?
    scope = scope.where("postgres_air.aircraft.range >= ?", params[:min_range]) if params[:min_range]
    scope = scope.where(status: params[:statuses]) if params[:statuses]&.any?
    if params[:cursor_time] && params[:cursor_id]
      scope = scope.where("postgres_air.flight.scheduled_departure > ? OR (postgres_air.flight.scheduled_departure = ? AND postgres_air.flight.flight_id > ?)",
                          params[:cursor_time], params[:cursor_time], params[:cursor_id])
    end
    scope.order("postgres_air.flight.scheduled_departure ASC, postgres_air.flight.flight_id ASC").limit(params[:limit] || 100).to_a
  end

  # HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
  def hq12_batch_upsert(updates)
    rows = []
    now_str = Time.now.utc.iso8601
    updates.each do |u|
      rows << "(#{u[:flight_id]}, '#{u[:status]}', '#{u[:actual_departure]}', '#{u[:actual_arrival]}', '#{now_str}', #{u[:version]})"
    end
    sql = <<-SQL
      INSERT INTO postgres_air.flight_status_update (flight_id, status, actual_departure, actual_arrival, update_ts, version)
      VALUES #{rows.join(', ')}
      ON CONFLICT (flight_id) DO UPDATE SET
        status = EXCLUDED.status,
        actual_departure = EXCLUDED.actual_departure,
        actual_arrival = EXCLUDED.actual_arrival,
        update_ts = EXCLUDED.update_ts,
        version = postgres_air.flight_status_update.version + 1
    SQL
    ActiveRecord::Base.connection.execute(sql)
    updates.size
  end

  # HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
  def hq13_optimistic_bulk_update(min_fid, max_fid, expected_ver, new_status)
    Flight.where(flight_id: min_fid..max_fid, version: expected_ver)
          .update_all(["status = ?, version = version + 1, update_ts = clock_timestamp()", new_status])
  end

  # HQ14: High-Concurrency Seat Allocation Under Contention (C=100)
  def hq14_reserve_seat_concurrent(flight_id, passenger_name)
    FlightSeatInventory.transaction do
      seat = FlightSeatInventory.where(flight_id: flight_id, status: 'AVAILABLE').lock("FOR UPDATE").first
      return 'Sold Out' unless seat

      seat.update_columns(status: 'RESERVED', passenger_name: passenger_name, reserved_at: Time.now, version: seat.version + 1)
      seat.seat_no
    end
  end

  # HQ15: Distributed Financial / Points Transfer with Serialization Retry
  def hq15_points_transfer_serializable(from_acc, to_acc, points)
    max_retries = 5
    max_retries.times do |attempt|
      begin
        FrequentFlyer.transaction(isolation: :serializable) do
          from_ff = FrequentFlyer.find(from_acc)
          to_ff = FrequentFlyer.find(to_acc)
          from_ff.update_columns(award_points: from_ff.award_points - points)
          to_ff.update_columns(award_points: to_ff.award_points + points)
        end
        return
      rescue ActiveRecord::SerializationFailure, PG::TRSerializationFailure, PG::UnableToSend => e
        if attempt < max_retries - 1
          sleep(0.01 * (2 ** attempt))
          next
        end
        raise e
      end
    end
  end

  # HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
  def hq16_hybrid_search_rrf(target_airport = 'LHR', query_text = 'London Heathrow international hub')
    sql = <<-SQL
      WITH text_ranking AS (
          SELECT airport_code,
                 ROW_NUMBER() OVER (ORDER BY ts_rank_cd(search_tsv, plainto_tsquery('english', '#{query_text}')) DESC) AS rank_text
          FROM postgres_air.airport
          WHERE search_tsv @@ plainto_tsquery('english', '#{query_text}')
          LIMIT 25
      ),
      vector_ranking AS (
          SELECT airport_code,
                 ROW_NUMBER() OVER (ORDER BY (embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = '#{target_airport}')) ASC) AS rank_vec
          FROM postgres_air.airport
          LIMIT 25
      ),
      airport_stats AS (
          SELECT departure_airport AS airport_code,
                 count(*)::bigint AS active_flights_count
          FROM postgres_air.flight
          WHERE scheduled_departure >= '2024-07-01' AND scheduled_departure < '2024-07-15'
          GROUP BY departure_airport
      ),
      rrf_scores AS (
          SELECT coalesce(t.airport_code, v.airport_code) AS airport_code,
                 (coalesce(1.0 / (60.0 + t.rank_text), 0.0) + coalesce(1.0 / (60.0 + v.rank_vec), 0.0))::float8 AS rrf_score
          FROM text_ranking t
          FULL OUTER JOIN vector_ranking v ON t.airport_code = v.airport_code
      )
      SELECT a.airport_code, a.airport_name, a.city,
             coalesce(s.active_flights_count, 0)::bigint AS active_flights,
             round(r.rrf_score::numeric, 6)::float8 AS final_rrf_score
      FROM rrf_scores r
      JOIN postgres_air.airport a ON r.airport_code = a.airport_code
      LEFT JOIN airport_stats s ON a.airport_code = s.airport_code
      ORDER BY final_rrf_score DESC
      LIMIT 10
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a
  end
end
