defmodule EctoAirBench.Queries do
  import Ecto.Query
  alias EctoAirBench.Repo
  alias EctoAirBench.Schemas.{Flight, Booking, Passenger, BookingLeg, BoardingPass, Account, FrequentFlyer, Phone, Airport, Aircraft, FlightSeatInventory, FlightStatusUpdate}

  # Structs for composite outputs
  defmodule CompositeBookingPassengerLegFlight do
    defstruct [
      :booking_id, :booking_ref, :price, :email,
      :passenger_id, :first_name, :last_name, :age,
      :booking_leg_id, :leg_num, :is_returning,
      :flight_id, :flight_no, :departure_airport, :arrival_airport,
      :scheduled_departure, :status
    ]
  end

  defmodule BookingLegNode do
    defstruct [:leg, :booking, :boarding_pass]
  end

  defmodule FlightGraph do
    defstruct [:flight, :legs]
  end

  # HQ01: Massive Entity Deserialization (10,000 Wide Rows)
  def hq01 do
    from(f in Flight,
      order_by: [asc: f.flight_id],
      limit: 10_000
    )
    |> Repo.all()
  end

  # HQ02: Wide Multi-Join Composite Hydration (5,000 Joined Records Across 4 Relations)
  def hq02 do
    from(b in Booking,
      join: p in Passenger, on: b.booking_id == p.booking_id,
      join: bl in BookingLeg, on: b.booking_id == bl.booking_id,
      join: f in Flight, on: bl.flight_id == f.flight_id,
      where: b.booking_id >= 100_000 and b.booking_id <= 105_000,
      order_by: [asc: b.booking_id, asc: p.passenger_id, asc: bl.booking_leg_id],
      limit: 5000,
      select: %CompositeBookingPassengerLegFlight{
        booking_id: b.booking_id,
        booking_ref: b.booking_ref,
        price: b.price,
        email: b.email,
        passenger_id: p.passenger_id,
        first_name: p.first_name,
        last_name: p.last_name,
        age: p.age,
        booking_leg_id: bl.booking_leg_id,
        leg_num: bl.leg_num,
        is_returning: bl.is_returning,
        flight_id: f.flight_id,
        flight_no: f.flight_no,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        status: f.status
      }
    )
    |> Repo.all()
  end

  # HQ03: 4-Level Deep Hierarchical Entity Tree Materialization
  def hq03 do
    rows = from(f in Flight,
      join: bl in BookingLeg, on: f.flight_id == bl.flight_id,
      join: b in Booking, on: bl.booking_id == b.booking_id,
      left_join: bp in BoardingPass, on: bp.booking_leg_id == bl.booking_leg_id,
      where: f.flight_id >= 2000 and f.flight_id <= 2025,
      order_by: [asc: f.flight_id, asc: bl.booking_leg_id, asc: bp.pass_id],
      select: {f, bl, b, bp}
    )
    |> Repo.all()

    # Group into FlightGraph nodes
    rows
    |> Enum.group_by(fn {f, _, _, _} -> f.flight_id end)
    |> Enum.map(fn {_fid, group_rows} ->
      {flight, _, _, _} = hd(group_rows)
      legs =
        group_rows
        |> Enum.group_by(fn {_, bl, _, _} -> bl.booking_leg_id end)
        |> Enum.map(fn {_bl_id, leg_rows} ->
          {_, leg, booking, bp} = hd(leg_rows)
          %BookingLegNode{
            leg: leg,
            booking: booking,
            boarding_pass: bp
          }
        end)

      %FlightGraph{
        flight: flight,
        legs: legs
      }
    end)
  end

  # HQ04: Account Relationship Graph with Optional Sub-Entities
  def hq04 do
    from(a in Account,
      left_join: ff in FrequentFlyer, on: a.frequent_flyer_id == ff.frequent_flyer_id,
      left_join: ph in Phone, on: a.account_id == ph.account_id,
      left_join: b in Booking, on: a.account_id == b.account_id,
      left_join: p in Passenger, on: b.booking_id == p.booking_id,
      where: a.account_id >= 50_000 and a.account_id <= 50_200,
      order_by: [asc: a.account_id, asc: ph.phone_id, asc: b.booking_id, asc: p.passenger_id],
      select: {
        a.account_id, a.login, a.first_name, a.last_name,
        ff.level, ff.award_points,
        ph.phone_id, ph.phone, ph.phone_type,
        b.booking_id, b.booking_ref, b.price,
        p.passenger_id, p.first_name, p.last_name
      }
    )
    |> Repo.all()
  end

  # HQ05: Fleet & Route Profitability Analytical Ledger (5-Table Join over 400k+ Rows)
  def hq05 do
    t_start = ~U[2024-07-01 00:00:00Z]
    t_end   = ~U[2024-07-04 00:00:00Z]

    from(f in Flight,
      join: orig in Airport, on: f.departure_airport == orig.airport_code,
      join: dest in Airport, on: f.arrival_airport == dest.airport_code,
      join: ac in Aircraft, on: f.aircraft_code == ac.code,
      join: bl in BookingLeg, on: f.flight_id == bl.flight_id,
      join: b in Booking, on: bl.booking_id == b.booking_id,
      where: f.scheduled_departure >= ^t_start and f.scheduled_departure < ^t_end,
      group_by: [orig.airport_code, dest.airport_code, ac.model],
      having: count(f.flight_id, :distinct) >= 3,
      order_by: [desc: sum(b.price)],
      limit: 50,
      select: %{
        origin: orig.airport_code,
        destination: dest.airport_code,
        aircraft_model: ac.model,
        total_flights: count(f.flight_id, :distinct),
        total_legs_booked: count(bl.booking_leg_id),
        total_revenue: fragment("round(sum(?), 2)", b.price),
        avg_delay_minutes: fragment("round(avg(EXTRACT(EPOCH FROM (? - ?)) / 60), 2)", f.actual_departure, f.scheduled_departure),
        on_time_pct: fragment("round(100.0 * count(CASE WHEN ? <= ? + INTERVAL '15 minutes' THEN 1 END) / count(?), 2)", f.actual_departure, f.scheduled_departure, f.flight_id)
      }
    )
    |> Repo.all()
  end

  # HQ06: Chained Multi-Stage CTEs (Airport Hub Centrality & Network Degree)
  def hq06 do
    t_start = ~U[2024-06-01 00:00:00Z]
    t_end   = ~U[2024-07-01 00:00:00Z]

    fv = from f in Flight,
      where: f.scheduled_departure >= ^t_start and f.scheduled_departure < ^t_end and not is_nil(f.actual_departure),
      group_by: f.departure_airport,
      select: %{
        airport_code: f.departure_airport,
        departures_count: count(f.flight_id),
        avg_dep_delay: fragment("round(avg(EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric, 2)", f.actual_departure, f.scheduled_departure)
      }

    av = from f in Flight,
      where: f.scheduled_arrival >= ^t_start and f.scheduled_arrival < ^t_end and not is_nil(f.actual_arrival),
      group_by: f.arrival_airport,
      select: %{
        airport_code: f.arrival_airport,
        arrivals_count: count(f.flight_id),
        avg_arr_delay: fragment("round(avg(EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric, 2)", f.actual_arrival, f.scheduled_arrival)
      }

    rc = from f in Flight,
      where: f.scheduled_departure >= ^t_start and f.scheduled_departure < ^t_end,
      group_by: f.departure_airport,
      select: %{
        airport_code: f.departure_airport,
        unique_destinations: count(f.arrival_airport, :distinct),
        fleet_diversity: count(f.aircraft_code, :distinct)
      }

    Airport
    |> with_cte("flight_volumes", as: ^fv)
    |> with_cte("arrival_volumes", as: ^av)
    |> with_cte("route_connectivity", as: ^rc)
    |> join(:inner, [a], fv in "flight_volumes", on: a.airport_code == fv.airport_code)
    |> join(:inner, [a, fv], av in "arrival_volumes", on: a.airport_code == av.airport_code)
    |> join(:inner, [a, fv, av], rc in "route_connectivity", on: a.airport_code == rc.airport_code)
    |> order_by([a, fv, av, rc], desc: fragment("round((coalesce(?, 0) + coalesce(?, 0)) * (1.0 + coalesce(?, 0) / 100.0) / (1.0 + greatest(coalesce(?, 0), 0) / 10.0), 2)", fv.departures_count, av.arrivals_count, rc.unique_destinations, fv.avg_dep_delay))
    |> limit(50)
    |> select([a, fv, av, rc], %{
      airport_code: a.airport_code,
      airport_name: a.airport_name,
      city: a.city,
      total_departures: fv.departures_count,
      total_arrivals: av.arrivals_count,
      unique_destinations: rc.unique_destinations,
      fleet_diversity: rc.fleet_diversity,
      avg_dep_delay: fv.avg_dep_delay,
      avg_arr_delay: av.avg_arr_delay,
      hub_centrality_score: fragment("round((coalesce(?, 0) + coalesce(?, 0)) * (1.0 + coalesce(?, 0) / 100.0) / (1.0 + greatest(coalesce(?, 0), 0) / 10.0), 2)", fv.departures_count, av.arrivals_count, rc.unique_destinations, fv.avg_dep_delay)
    })
    |> Repo.all()
  end

  # HQ07: Correlated At-Capacity Subquery with Loyalty Tier Cross-Check
  def hq07 do
    t_start = ~U[2024-07-01 00:00:00Z]
    t_end   = ~U[2024-07-03 00:00:00Z]
    t_cancel = ~U[2024-06-01 00:00:00Z]

    seats_booked_sq = from bl in BookingLeg,
      where: bl.flight_id == parent_as(:f).flight_id,
      select: count(bl.booking_leg_id)

    elite_flyer_sq = from bl in BookingLeg,
      join: p in Passenger, on: bl.booking_id == p.booking_id,
      join: a in Account, on: p.account_id == a.account_id,
      join: ff in FrequentFlyer, on: a.frequent_flyer_id == ff.frequent_flyer_id,
      where: bl.flight_id == parent_as(:f).flight_id and ff.level >= 3,
      select: count(bl.booking_leg_id)

    canceled_exists_sq = from route_f in Flight,
      where: route_f.departure_airport == parent_as(:f).departure_airport and
             route_f.arrival_airport == parent_as(:f).arrival_airport and
             route_f.status == "Canceled" and
             route_f.scheduled_departure >= ^t_cancel

    from(f in Flight,
      as: :f,
      join: ac in Aircraft, on: f.aircraft_code == ac.code,
      where: f.scheduled_departure >= ^t_start and f.scheduled_departure < ^t_end and
             ac.class >= 2 and
             subquery(seats_booked_sq) > 40 and
             exists(canceled_exists_sq),
      order_by: [desc: subquery(seats_booked_sq)],
      limit: 100,
      select: %{
        flight_id: f.flight_id,
        flight_no: f.flight_no,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        aircraft_model: ac.model,
        aircraft_range: ac.range,
        seats_booked: subquery(seats_booked_sq),
        elite_flyer_count: subquery(elite_flyer_sq)
      }
    )
    |> Repo.all()
  end

  # HQ08: Recursive Multi-Hop Flight Connection Graph Search (1- to 3-Hop Paths)
  def hq08 do
    t_start = ~U[2024-07-05 00:00:00Z]
    t_end   = ~U[2024-07-06 00:00:00Z]

    base = from f in Flight,
      where: f.departure_airport == "JFK" and
             f.scheduled_departure >= ^t_start and
             f.scheduled_departure < ^t_end,
      select: %{
        flight_id: f.flight_id,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        scheduled_arrival: f.scheduled_arrival,
        hops: 1,
        route_airports: fragment("ARRAY[?::text, ?::text]", f.departure_airport, f.arrival_airport),
        route_flights: fragment("ARRAY[?]", f.flight_id),
        journey_start: f.scheduled_departure,
        journey_end: f.scheduled_arrival,
        total_flight_minutes: fragment("(EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric(10,2)", f.scheduled_arrival, f.scheduled_departure)
      }

    recur = from next_f in Flight,
      join: fp in "flight_paths", on: fp.arrival_airport == next_f.departure_airport,
      where: fp.hops < 3 and
             next_f.scheduled_departure >= fragment("? + INTERVAL '60 minutes'", fp.scheduled_arrival) and
             next_f.scheduled_departure <= fragment("? + INTERVAL '360 minutes'", fp.scheduled_arrival) and
             fragment("NOT (?::text = ANY(?))", next_f.arrival_airport, fp.route_airports),
      select: %{
        flight_id: next_f.flight_id,
        departure_airport: fp.departure_airport,
        arrival_airport: next_f.arrival_airport,
        scheduled_departure: next_f.scheduled_departure,
        scheduled_arrival: next_f.scheduled_arrival,
        hops: fp.hops + 1,
        route_airports: fragment("? || ?::text", fp.route_airports, next_f.arrival_airport),
        route_flights: fragment("? || ?", fp.route_flights, next_f.flight_id),
        journey_start: fp.journey_start,
        journey_end: next_f.scheduled_arrival,
        total_flight_minutes: fragment("(? + (EXTRACT(EPOCH FROM (? - ?)) / 60))::numeric(10,2)", fp.total_flight_minutes, next_f.scheduled_arrival, next_f.scheduled_departure)
      }

    cte_union = union_all(base, ^recur)

    "flight_paths"
    |> recursive_ctes(true)
    |> with_cte("flight_paths", as: ^cte_union)
    |> where([fp], fp.arrival_airport == "ORD")
    |> order_by([fp], [asc: fp.hops, asc: fragment("(EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric(10,2)", fp.journey_end, fp.journey_start)])
    |> limit(25)
    |> select([fp], %{
      hops: fp.hops,
      route: fragment("array_to_string(?, ' -> ')", fp.route_airports),
      journey_start: fp.journey_start,
      journey_end: fp.journey_end,
      total_elapsed_minutes: fragment("(EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric(10,2)", fp.journey_end, fp.journey_start),
      total_flight_minutes: fp.total_flight_minutes
    })
    |> Repo.all()
  end

  # HQ09: Multi-Window Statistical Delay Dispersion & Cascades
  def hq09 do
    t_start = ~U[2024-06-01 00:00:00Z]
    t_end   = ~U[2024-07-01 00:00:00Z]

    flight_delays = from f in Flight,
      where: f.departure_airport == "ORD" and
             not is_nil(f.actual_departure) and
             f.scheduled_departure >= ^t_start and
             f.scheduled_departure < ^t_end,
      select: %{
        flight_id: f.flight_id,
        flight_no: f.flight_no,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        delay_minutes: fragment("round((EXTRACT(EPOCH FROM (? - ?)) / 60)::numeric, 2)", f.actual_departure, f.scheduled_departure)
      }

    "flight_delays"
    |> with_cte("flight_delays", as: ^flight_delays)
    |> order_by([d], [asc: d.departure_airport, asc: d.arrival_airport, asc: d.scheduled_departure])
    |> limit(5000)
    |> select([d], %{
      flight_id: d.flight_id,
      flight_no: d.flight_no,
      arrival_airport: d.arrival_airport,
      scheduled_departure: d.scheduled_departure,
      delay_minutes: d.delay_minutes,
      rolling_avg_delay_5: fragment("round(avg(?) OVER (PARTITION BY ?, ? ORDER BY ? ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 2)", d.delay_minutes, d.departure_airport, d.arrival_airport, d.scheduled_departure),
      delay_diff_prev: fragment("? - lag(?, 1) OVER (PARTITION BY ?, ? ORDER BY ?)", d.delay_minutes, d.delay_minutes, d.departure_airport, d.arrival_airport, d.scheduled_departure),
      rolling_stddev_10: fragment("round(coalesce(stddev_samp(?) OVER (PARTITION BY ?, ? ORDER BY ? ROWS BETWEEN 9 PRECEDING AND CURRENT ROW), 0), 2)", d.delay_minutes, d.departure_airport, d.arrival_airport, d.scheduled_departure),
      severity_rank: fragment("dense_rank() OVER (PARTITION BY ?, ? ORDER BY ? DESC)", d.departure_airport, d.arrival_airport, d.delay_minutes)
    })
    |> Repo.all()
  end

  # HQ10: High-Throughput Keyset (Cursor) Pagination over Composite Tuple Under Concurrency
  def hq10 do
    t_cursor = ~U[2024-07-15 12:00:00Z]
    cursor_id = 10500

    from(f in Flight,
      where: fragment("(?, ?) > (?, ?)", f.scheduled_departure, f.flight_id, ^t_cursor, ^cursor_id),
      order_by: [asc: f.scheduled_departure, asc: f.flight_id],
      limit: 50,
      select: %{
        flight_id: f.flight_id,
        flight_no: f.flight_no,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        status: f.status
      }
    )
    |> Repo.all()
  end

  # HQ11: High-Dimensional Dynamic Faceted Flight Search Engine (10 Optional Predicates)
  def hq11 do
    dep_airports = ["JFK", "BOS", "EWR"]
    arr_airports = ["LAX", "SFO", "SEA"]
    t_min = ~U[2024-07-01 00:00:00Z]
    t_max = ~U[2024-07-15 23:59:59Z]
    classes = [1, 2, 3]
    min_range = 2000
    statuses = ["On time", "Delayed"]
    h_min = 6
    h_max = 21
    c_time = ~U[2024-07-01 06:00:00Z]
    c_id = 500

    dyn = dynamic(true)
    dyn = dynamic([f, ac], ^dyn and f.departure_airport in ^dep_airports)
    dyn = dynamic([f, ac], ^dyn and f.arrival_airport in ^arr_airports)
    dyn = dynamic([f, ac], ^dyn and f.scheduled_departure >= ^t_min)
    dyn = dynamic([f, ac], ^dyn and f.scheduled_departure <= ^t_max)
    dyn = dynamic([f, ac], ^dyn and ac.class in ^classes)
    dyn = dynamic([f, ac], ^dyn and ac.range >= ^min_range)
    dyn = dynamic([f, ac], ^dyn and f.status in ^statuses)
    dyn = dynamic([f, ac], ^dyn and fragment("EXTRACT(HOUR FROM ?) BETWEEN ? AND ?", f.scheduled_departure, ^h_min, ^h_max))
    dyn = dynamic([f, ac], ^dyn and fragment("(?, ?) > (?, ?)", f.scheduled_departure, f.flight_id, ^c_time, ^c_id))

    from(f in Flight,
      join: ac in Aircraft, on: f.aircraft_code == ac.code,
      where: ^dyn,
      order_by: [asc: f.scheduled_departure, asc: f.flight_id],
      limit: 100,
      select: %{
        flight_id: f.flight_id,
        flight_no: f.flight_no,
        departure_airport: f.departure_airport,
        arrival_airport: f.arrival_airport,
        scheduled_departure: f.scheduled_departure,
        scheduled_arrival: f.scheduled_arrival,
        status: f.status,
        aircraft_model: ac.model,
        aircraft_range: ac.range,
        aircraft_class: ac.class
      }
    )
    |> Repo.all()
  end

  # HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
  def hq12 do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    rows = for i <- 1..2500 do
      %{
        flight_id: i,
        status: "Departed",
        actual_departure: ~U[2024-07-01 08:05:00Z],
        actual_arrival: ~U[2024-07-01 11:15:00Z],
        update_ts: now,
        version: 1
      }
    end

    {count, _} = Repo.insert_all(FlightStatusUpdate, rows,
      on_conflict: [
        set: [
          status: dynamic(fragment("EXCLUDED.status")),
          actual_departure: dynamic(fragment("EXCLUDED.actual_departure")),
          actual_arrival: dynamic(fragment("EXCLUDED.actual_arrival")),
          update_ts: dynamic(fragment("EXCLUDED.update_ts")),
          version: dynamic([f], f.version + 1)
        ]
      ],
      conflict_target: :flight_id
    )
    count
  end

  # HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
  def hq13 do
    query = from f in Flight,
      where: f.flight_id >= 1000 and f.flight_id <= 1050 and f.version == 1,
      update: [
        set: [
          status: "Boarding",
          version: f.version + 1,
          update_ts: fragment("clock_timestamp()")
        ]
      ],
      select: {f.flight_id, f.version}

    {count, rows} = Repo.update_all(query, [])
    # Reset back to version 1 for subsequent runs
    Repo.update_all(from(f in Flight, where: f.flight_id >= 1000 and f.flight_id <= 1050), set: [status: "Departed", version: 1])
    {count, rows}
  end

  # HQ14: High-Concurrency Seat Inventory Allocation Under Contention (C=50, 100)
  def hq14 do
    Repo.transaction(fn ->
      seat = Repo.one(
        from s in FlightSeatInventory,
          where: s.flight_id == 101 and s.status == "AVAILABLE",
          limit: 1,
          lock: "FOR UPDATE"
      )

      if seat do
        {1, _} = Repo.update_all(
          from(s in FlightSeatInventory,
            where: s.flight_id == 101 and s.seat_no == ^seat.seat_no and s.version == ^seat.version
          ),
          set: [
            status: "RESERVED",
            passenger_name: "Test Concurrent Flyer",
            reserved_at: DateTime.utc_now() |> DateTime.truncate(:second),
            version: seat.version + 1
          ]
        )
        {:ok, seat.seat_no}
      else
        {:error, :no_seats}
      end
    end)
  end

  # HQ15: Distributed Financial / Points Transfer with Serialization Retry
  def hq15 do
    transfer = fn ->
      Repo.transaction(fn ->
        {1, _} = Repo.update_all(
          from(ff in FrequentFlyer, where: ff.frequent_flyer_id == 1001),
          inc: [award_points: -500]
        )
        {1, _} = Repo.update_all(
          from(ff in FrequentFlyer, where: ff.frequent_flyer_id == 1002),
          inc: [award_points: 500]
        )
        :ok
      end, isolation_level: :serializable)
    end

    execute_with_retry(transfer, 5)
  end

  defp execute_with_retry(fun, retries) do
    Enum.reduce_while(1..retries, nil, fn attempt, _acc ->
      try do
        case fun.() do
          {:ok, res} -> {:halt, {:ok, res}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      rescue
        e in Postgrex.Error ->
          if e.postgres != nil and e.postgres[:code] == :serialization_failure and attempt < retries do
            :timer.sleep(attempt * 10)
            {:cont, {:retry, attempt}}
          else
            reraise e, __STACKTRACE__
          end
      end
    end)
  end

  # HQ16: Multi-Modal Hybrid Vector Similarity + BM25 Full-Text Search with RRF Reranking
  def hq16 do
    text_ranking = from a in "airport",
      where: fragment("? @@ plainto_tsquery('english', 'London Heathrow international hub')", a.search_tsv),
      order_by: [desc: fragment("ts_rank_cd(?, plainto_tsquery('english', 'London Heathrow international hub'))", a.search_tsv)],
      limit: 25,
      select: %{
        airport_code: a.airport_code,
        rank_text: fragment("ROW_NUMBER() OVER (ORDER BY ts_rank_cd(?, plainto_tsquery('english', 'London Heathrow international hub')) DESC)", a.search_tsv)
      }

    vector_ranking = from a in "airport",
      order_by: [asc: fragment("? <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = 'LHR')", a.embedding)],
      limit: 25,
      select: %{
        airport_code: a.airport_code,
        rank_vec: fragment("ROW_NUMBER() OVER (ORDER BY ? <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = 'LHR') ASC)", a.embedding)
      }

    t_start = ~U[2024-07-01 00:00:00Z]
    t_end   = ~U[2024-07-08 00:00:00Z]

    airport_stats = from f in Flight,
      where: f.scheduled_departure >= ^t_start and f.scheduled_departure < ^t_end,
      group_by: f.departure_airport,
      select: %{
        airport_code: f.departure_airport,
        active_flights_count: count(f.flight_id)
      }

    "text_ranking"
    |> with_cte("text_ranking", as: ^text_ranking)
    |> with_cte("vector_ranking", as: ^vector_ranking)
    |> with_cte("airport_stats", as: ^airport_stats)
    |> join(:full, [t], v in "vector_ranking", on: t.airport_code == v.airport_code)
    |> join(:inner, [t, v], a in Airport, on: a.airport_code == fragment("COALESCE(?, ?)", t.airport_code, v.airport_code))
    |> join(:left, [t, v, a], ast in "airport_stats", on: ast.airport_code == fragment("COALESCE(?, ?)", t.airport_code, v.airport_code))
    |> order_by([t, v, a, ast], desc: fragment("round((COALESCE(1.0 / (60 + ?), 0.0) + COALESCE(1.0 / (60 + ?), 0.0))::numeric, 5)", t.rank_text, v.rank_vec))
    |> limit(25)
    |> select([t, v, a, ast], %{
      airport_code: fragment("COALESCE(?, ?)", t.airport_code, v.airport_code),
      airport_name: a.airport_name,
      city: a.city,
      active_flights_count: fragment("COALESCE(?, 0)", ast.active_flights_count),
      rrf_score: fragment("round((COALESCE(1.0 / (60 + ?), 0.0) + COALESCE(1.0 / (60 + ?), 0.0))::numeric, 5)", t.rank_text, v.rank_vec)
    })
    |> Repo.all()
  end
end
