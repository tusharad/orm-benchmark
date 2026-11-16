"""
SQLAlchemy Canonical Queries Implementation (HQ01–HQ16).
"""
from __future__ import annotations
import asyncio
from datetime import datetime
from decimal import Decimal
from typing import List, Optional, Tuple
import sqlalchemy as sa
from sqlalchemy.orm import selectinload, aliased
from sqlalchemy.dialects.postgresql import insert as pg_insert, array as pg_array
from sqlalchemy.ext.asyncio import AsyncSession

try:
    from .models import (
        Aircraft,
        Airport,
        Flight,
        Booking,
        BookingLeg,
        Passenger,
        BoardingPass,
        Account,
        Phone,
        FrequentFlyer,
        FlightSeatInventory,
        FlightStatusUpdate,
        CompositeBookingRecord,
        RouteFinancialLedger,
        HubCentralityRecord,
        AtCapacityFlightRecord,
        FlightPathResult,
        FlightDelayDispersion,
        KeysetFlight,
        FacetedFlightResult,
        HybridAirportResult,
    )
except ImportError:
    from models import (
        Aircraft,
        Airport,
        Flight,
        Booking,
        BookingLeg,
        Passenger,
        BoardingPass,
        Account,
        Phone,
        FrequentFlyer,
        FlightSeatInventory,
        FlightStatusUpdate,
        CompositeBookingRecord,
        RouteFinancialLedger,
        HubCentralityRecord,
        AtCapacityFlightRecord,
        FlightPathResult,
        FlightDelayDispersion,
        KeysetFlight,
        FacetedFlightResult,
        HybridAirportResult,
    )

# HQ01: Massive Entity Deserialization (10k Wide Rows)
async def hq01_massive_deserialization(session: AsyncSession) -> List[Flight]:
    stmt = sa.select(Flight).order_by(Flight.flight_id).limit(10000)
    res = await session.scalars(stmt)
    return list(res.all())

# HQ02: Wide Multi-Join Composite Hydration (5k Joined Rows)
async def hq02_wide_multi_join(session: AsyncSession) -> List[CompositeBookingRecord]:
    stmt = (
        sa.select(
            Booking.booking_id,
            Booking.booking_ref,
            Booking.price,
            Booking.email,
            Passenger.passenger_id,
            Passenger.first_name,
            Passenger.last_name,
            Passenger.age,
            BookingLeg.booking_leg_id,
            BookingLeg.leg_num,
            BookingLeg.is_returning,
            Flight.flight_id,
            Flight.flight_no,
            Flight.departure_airport,
            Flight.arrival_airport,
            Flight.scheduled_departure,
            Flight.status,
        )
        .join(Passenger, Booking.booking_id == Passenger.booking_id)
        .join(BookingLeg, Booking.booking_id == BookingLeg.booking_id)
        .join(Flight, BookingLeg.flight_id == Flight.flight_id)
        .where(sa.between(Booking.booking_id, 100000, 105000))
        .order_by(Booking.booking_id, Passenger.passenger_id, BookingLeg.booking_leg_id)
        .limit(5000)
    )
    res = await session.execute(stmt)
    return [CompositeBookingRecord(*row) for row in res.all()]

# HQ03: 4-Level Deep Entity Tree (Flight -> Legs -> Booking -> Pass) (0 N+1)
async def hq03_deep_hierarchical_graph(session: AsyncSession) -> List[Flight]:
    stmt = (
        sa.select(Flight)
        .options(
            selectinload(Flight.booking_legs).selectinload(BookingLeg.booking),
            selectinload(Flight.booking_legs).selectinload(BookingLeg.boarding_passes),
        )
        .where(sa.between(Flight.flight_id, 2000, 2025))
        .order_by(Flight.flight_id)
    )
    res = await session.scalars(stmt)
    return list(res.all())

# HQ04: Account Relationship Graph with Optional Sub-Entities
async def hq04_account_relationship_graph(session: AsyncSession) -> List[Account]:
    stmt = (
        sa.select(Account)
        .options(
            selectinload(Account.frequent_flyer),
            selectinload(Account.phones),
            selectinload(Account.bookings).selectinload(Booking.passengers),
        )
        .where(sa.between(Account.account_id, 50000, 50200))
        .order_by(Account.account_id)
    )
    res = await session.scalars(stmt)
    return list(res.all())

# HQ05: Fleet & Route Profitability Ledger (5 Tables, 400k+ Rows)
async def hq05_route_financial_ledger(session: AsyncSession) -> List[RouteFinancialLedger]:
    orig = aliased(Airport, name="orig")
    dest = aliased(Airport, name="dest")
    delay_epoch = sa.func.extract("epoch", Flight.actual_departure - Flight.scheduled_departure) / 60
    on_time_case = sa.case(
        (Flight.actual_departure <= Flight.scheduled_departure + sa.text("INTERVAL '15 minutes'"), 1),
        else_=None,
    )
    stmt = (
        sa.select(
            orig.airport_code.label("origin"),
            dest.airport_code.label("destination"),
            Aircraft.model.label("aircraft_model"),
            sa.func.count(sa.distinct(Flight.flight_id)).label("total_flights"),
            sa.func.count(BookingLeg.booking_leg_id).label("total_legs_booked"),
            sa.func.round(sa.cast(sa.func.sum(Booking.price), sa.Numeric), 2).label("total_revenue"),
            sa.func.round(sa.cast(sa.func.avg(delay_epoch), sa.Numeric), 2).label("avg_delay_minutes"),
            sa.func.round(sa.cast(100.0 * sa.func.count(on_time_case) / sa.func.count(Flight.flight_id), sa.Numeric), 2).label("on_time_pct"),
        )
        .select_from(Flight)
        .join(orig, Flight.departure_airport == orig.airport_code)
        .join(dest, Flight.arrival_airport == dest.airport_code)
        .join(Aircraft, Flight.aircraft_code == Aircraft.code)
        .join(BookingLeg, Flight.flight_id == BookingLeg.flight_id)
        .join(Booking, BookingLeg.booking_id == Booking.booking_id)
        .where(
            Flight.scheduled_departure >= sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-04 00:00:00+00'::timestamptz"),
        )
        .group_by(orig.airport_code, dest.airport_code, Aircraft.model)
        .having(sa.func.count(sa.distinct(Flight.flight_id)) >= 3)
        .order_by(sa.desc(sa.literal_column("total_revenue")))
        .limit(50)
    )
    res = await session.execute(stmt)
    return [RouteFinancialLedger(*row) for row in res.all()]

# HQ06: Chained Multi-Stage CTEs (Hub Centrality & Degree)
async def hq06_chained_ctes_hub_centrality(session: AsyncSession) -> List[HubCentralityRecord]:
    dep_delay = sa.func.extract("epoch", Flight.actual_departure - Flight.scheduled_departure) / 60
    arr_delay = sa.func.extract("epoch", Flight.actual_arrival - Flight.scheduled_arrival) / 60

    fv_cte = (
        sa.select(
            Flight.departure_airport.label("airport_code"),
            sa.func.count().label("departures_count"),
            sa.func.round(sa.cast(sa.func.avg(dep_delay), sa.Numeric), 2).label("avg_dep_delay"),
        )
        .where(
            Flight.scheduled_departure >= sa.text("'2024-06-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
            Flight.actual_departure.is_not(None),
        )
        .group_by(Flight.departure_airport)
        .cte("flight_volumes")
    )

    av_cte = (
        sa.select(
            Flight.arrival_airport.label("airport_code"),
            sa.func.count().label("arrivals_count"),
            sa.func.round(sa.cast(sa.func.avg(arr_delay), sa.Numeric), 2).label("avg_arr_delay"),
        )
        .where(
            Flight.scheduled_arrival >= sa.text("'2024-06-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_arrival < sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
            Flight.actual_arrival.is_not(None),
        )
        .group_by(Flight.arrival_airport)
        .cte("arrival_volumes")
    )

    rc_cte = (
        sa.select(
            Flight.departure_airport.label("airport_code"),
            sa.func.count(sa.distinct(Flight.arrival_airport)).label("unique_destinations"),
            sa.func.count(sa.distinct(Flight.aircraft_code)).label("fleet_diversity"),
        )
        .where(
            Flight.scheduled_departure >= sa.text("'2024-06-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
        )
        .group_by(Flight.departure_airport)
        .cte("route_connectivity")
    )

    tot_dep = sa.func.coalesce(fv_cte.c.departures_count, 0)
    tot_arr = sa.func.coalesce(av_cte.c.arrivals_count, 0)
    uniq_dest = sa.func.coalesce(rc_cte.c.unique_destinations, 0)
    fleet_div = sa.func.coalesce(rc_cte.c.fleet_diversity, 0)
    avg_dep = sa.func.coalesce(fv_cte.c.avg_dep_delay, 0)
    avg_arr = sa.func.coalesce(av_cte.c.avg_arr_delay, 0)

    hub_score = sa.func.round(
        sa.cast(
            (tot_dep + tot_arr) * (1.0 + uniq_dest / 100.0) / (1.0 + sa.func.greatest(avg_dep, 0) / 10.0),
            sa.Numeric,
        ),
        2,
    ).label("hub_centrality_score")

    stmt = (
        sa.select(
            Airport.airport_code,
            Airport.airport_name,
            Airport.city,
            tot_dep.label("total_departures"),
            tot_arr.label("total_arrivals"),
            uniq_dest.label("unique_destinations"),
            fleet_div.label("fleet_diversity"),
            avg_dep.label("avg_dep_delay"),
            avg_arr.label("avg_arr_delay"),
            hub_score,
        )
        .select_from(Airport)
        .join(fv_cte, Airport.airport_code == fv_cte.c.airport_code)
        .join(av_cte, Airport.airport_code == av_cte.c.airport_code)
        .join(rc_cte, Airport.airport_code == rc_cte.c.airport_code)
        .order_by(sa.desc(sa.literal_column("hub_centrality_score")))
        .limit(50)
    )
    res = await session.execute(stmt)
    return [HubCentralityRecord(*row) for row in res.all()]

# HQ07: Correlated At-Capacity Subquery + Loyalty Cross-Check
async def hq07_correlated_subqueries(session: AsyncSession) -> List[AtCapacityFlightRecord]:
    bl_sub1 = aliased(BookingLeg, name="bl_sub1")
    seats_booked_subq = (
        sa.select(sa.func.count())
        .select_from(bl_sub1)
        .where(bl_sub1.flight_id == Flight.flight_id)
        .scalar_subquery()
    )

    bl_sub2 = aliased(BookingLeg, name="bl_sub2")
    p_sub = aliased(Passenger, name="p_sub")
    a_sub = aliased(Account, name="a_sub")
    ff_sub = aliased(FrequentFlyer, name="ff_sub")
    elite_flyer_subq = (
        sa.select(sa.func.count())
        .select_from(bl_sub2)
        .join(p_sub, bl_sub2.booking_id == p_sub.booking_id)
        .join(a_sub, p_sub.account_id == a_sub.account_id)
        .join(ff_sub, a_sub.frequent_flyer_id == ff_sub.frequent_flyer_id)
        .where(
            bl_sub2.flight_id == Flight.flight_id,
            ff_sub.level >= 3,
        )
        .scalar_subquery()
    )

    route_f = aliased(Flight, name="route_f")
    exists_canceled = sa.exists(
        sa.select(1)
        .select_from(route_f)
        .where(
            route_f.departure_airport == Flight.departure_airport,
            route_f.arrival_airport == Flight.arrival_airport,
            route_f.status == "Canceled",
            route_f.scheduled_departure >= sa.text("'2024-06-01 00:00:00+00'::timestamptz"),
        )
    )

    stmt = (
        sa.select(
            Flight.flight_id,
            Flight.flight_no,
            Flight.departure_airport,
            Flight.arrival_airport,
            Flight.scheduled_departure,
            Aircraft.model.label("aircraft_model"),
            Aircraft.range.label("aircraft_range"),
            seats_booked_subq.label("seats_booked"),
            elite_flyer_subq.label("elite_flyer_count"),
        )
        .join(Aircraft, Flight.aircraft_code == Aircraft.code)
        .where(
            Flight.scheduled_departure >= sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-03 00:00:00+00'::timestamptz"),
            Aircraft.class_ >= 2,
            seats_booked_subq > 40,
            exists_canceled,
        )
        .order_by(sa.desc(sa.literal_column("seats_booked")))
        .limit(100)
    )
    res = await session.execute(stmt)
    return [AtCapacityFlightRecord(*row) for row in res.all()]

# HQ08: Recursive Multi-Hop Flight Connection Graph (1-3 Hops)
async def hq08_recursive_multi_hop(session: AsyncSession) -> List[FlightPathResult]:
    base_flight = aliased(Flight, name="f")
    base_elapsed = sa.func.extract("epoch", base_flight.scheduled_arrival - base_flight.scheduled_departure) / 60
    base = (
        sa.select(
            base_flight.flight_id,
            sa.cast(base_flight.departure_airport, sa.Text).label("departure_airport"),
            sa.cast(base_flight.arrival_airport, sa.Text).label("arrival_airport"),
            base_flight.scheduled_departure,
            base_flight.scheduled_arrival,
            sa.literal(1).label("hops"),
            pg_array([sa.cast(base_flight.departure_airport, sa.Text), sa.cast(base_flight.arrival_airport, sa.Text)]).label("route_airports"),
            pg_array([base_flight.flight_id]).label("route_flights"),
            base_flight.scheduled_departure.label("journey_start"),
            base_flight.scheduled_arrival.label("journey_end"),
            sa.cast(base_elapsed, sa.Numeric(10, 2)).label("total_flight_minutes"),
        )
        .where(
            base_flight.departure_airport == "JFK",
            base_flight.scheduled_departure >= sa.text("'2024-07-05 00:00:00+00'::timestamptz"),
            base_flight.scheduled_departure < sa.text("'2024-07-06 00:00:00+00'::timestamptz"),
        )
    )

    flight_paths = base.cte("flight_paths", recursive=True)

    next_f = aliased(Flight, name="next_f")
    next_elapsed = sa.func.extract("epoch", next_f.scheduled_arrival - next_f.scheduled_departure) / 60
    rec = (
        sa.select(
            next_f.flight_id,
            flight_paths.c.departure_airport,
            sa.cast(next_f.arrival_airport, sa.Text).label("arrival_airport"),
            next_f.scheduled_departure,
            next_f.scheduled_arrival,
            (flight_paths.c.hops + 1).label("hops"),
            sa.func.array_cat(flight_paths.c.route_airports, pg_array([sa.cast(next_f.arrival_airport, sa.Text)])).label("route_airports"),
            sa.func.array_cat(flight_paths.c.route_flights, pg_array([next_f.flight_id])).label("route_flights"),
            flight_paths.c.journey_start,
            next_f.scheduled_arrival.label("journey_end"),
            sa.cast(flight_paths.c.total_flight_minutes + next_elapsed, sa.Numeric(10, 2)).label("total_flight_minutes"),
        )
        .join(next_f, flight_paths.c.arrival_airport == next_f.departure_airport)
        .where(
            flight_paths.c.hops < 3,
            next_f.scheduled_departure >= flight_paths.c.scheduled_arrival + sa.text("INTERVAL '60 minutes'"),
            next_f.scheduled_departure <= flight_paths.c.scheduled_arrival + sa.text("INTERVAL '360 minutes'"),
            ~sa.cast(next_f.arrival_airport, sa.Text).op("=")(sa.any_(flight_paths.c.route_airports)),
        )
    )

    flight_paths = flight_paths.union_all(rec)

    tot_elapsed = sa.func.extract("epoch", flight_paths.c.journey_end - flight_paths.c.journey_start) / 60
    stmt = (
        sa.select(
            flight_paths.c.hops,
            sa.func.array_to_string(flight_paths.c.route_airports, " -> ").label("route"),
            flight_paths.c.journey_start,
            flight_paths.c.journey_end,
            sa.cast(tot_elapsed, sa.Numeric(10, 2)).label("total_elapsed_minutes"),
            flight_paths.c.total_flight_minutes,
        )
        .where(flight_paths.c.arrival_airport == "ORD")
        .order_by(flight_paths.c.hops.asc(), sa.literal_column("total_elapsed_minutes").asc())
        .limit(25)
    )
    res = await session.execute(stmt)
    return [FlightPathResult(*row) for row in res.all()]

# HQ09: Multi-Window Statistical Delay Dispersion & Cascades
async def hq09_window_statistical_dispersion(session: AsyncSession) -> List[FlightDelayDispersion]:
    delay_min = sa.func.round(sa.cast(sa.func.extract("epoch", Flight.actual_departure - Flight.scheduled_departure) / 60, sa.Numeric), 2)
    delays_cte = (
        sa.select(
            Flight.flight_id,
            Flight.flight_no,
            Flight.departure_airport,
            Flight.arrival_airport,
            Flight.scheduled_departure,
            Flight.actual_departure,
            delay_min.label("delay_minutes"),
        )
        .where(
            Flight.departure_airport == "ORD",
            Flight.actual_departure.is_not(None),
            Flight.scheduled_departure >= sa.text("'2024-06-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
        )
        .cte("flight_delays")
    )

    w_part = sa.over(
        sa.func.avg(delays_cte.c.delay_minutes),
        partition_by=[delays_cte.c.departure_airport, delays_cte.c.arrival_airport],
        order_by=delays_cte.c.scheduled_departure,
        rows=(-4, 0),
    )
    w_lag = sa.over(
        sa.func.lag(delays_cte.c.delay_minutes, 1),
        partition_by=[delays_cte.c.departure_airport, delays_cte.c.arrival_airport],
        order_by=delays_cte.c.scheduled_departure,
    )
    w_std = sa.over(
        sa.func.stddev_samp(delays_cte.c.delay_minutes),
        partition_by=[delays_cte.c.departure_airport, delays_cte.c.arrival_airport],
        order_by=delays_cte.c.scheduled_departure,
        rows=(-9, 0),
    )
    w_dense = sa.over(
        sa.func.dense_rank(),
        partition_by=[delays_cte.c.departure_airport, delays_cte.c.arrival_airport],
        order_by=sa.desc(delays_cte.c.delay_minutes),
    )

    stmt = (
        sa.select(
            delays_cte.c.flight_id,
            delays_cte.c.flight_no,
            delays_cte.c.arrival_airport,
            delays_cte.c.scheduled_departure,
            delays_cte.c.delay_minutes,
            sa.func.round(sa.cast(w_part, sa.Numeric), 2).label("rolling_avg_delay_5"),
            (delays_cte.c.delay_minutes - w_lag).label("delay_diff_prev"),
            sa.func.round(sa.cast(sa.func.coalesce(w_std, 0), sa.Numeric), 2).label("rolling_stddev_10"),
            w_dense.label("severity_rank"),
        )
        .order_by(delays_cte.c.departure_airport, delays_cte.c.arrival_airport, delays_cte.c.scheduled_departure)
        .limit(5000)
    )
    res = await session.execute(stmt)
    return [FlightDelayDispersion(*row) for row in res.all()]

# HQ10: Composite Keyset Cursor Pagination
async def hq10_keyset_pagination(
    session: AsyncSession,
    cursor_time: datetime,
    cursor_id: int,
    limit: int = 50,
) -> List[KeysetFlight]:
    stmt = (
        sa.select(
            Flight.flight_id,
            Flight.flight_no,
            Flight.departure_airport,
            Flight.arrival_airport,
            Flight.scheduled_departure,
            Flight.status,
        )
        .where(
            sa.tuple_(Flight.scheduled_departure, Flight.flight_id) > (cursor_time, cursor_id)
        )
        .order_by(Flight.scheduled_departure.asc(), Flight.flight_id.asc())
        .limit(limit)
    )
    res = await session.execute(stmt)
    return [KeysetFlight(*row) for row in res.all()]

# HQ11: Dynamic Faceted Flight Search Engine (10 Predicates)
async def hq11_dynamic_faceted_search(
    session: AsyncSession,
    origins: Optional[List[str]] = None,
    destinations: Optional[List[str]] = None,
    min_departure: Optional[datetime] = None,
    max_departure: Optional[datetime] = None,
    aircraft_classes: Optional[List[int]] = None,
    min_range: Optional[Decimal] = None,
    statuses: Optional[List[str]] = None,
    hour_range: Optional[Tuple[int, int]] = None,
    cursor: Optional[Tuple[datetime, int]] = None,
    limit: int = 100,
) -> List[FacetedFlightResult]:
    stmt = (
        sa.select(
            Flight.flight_id,
            Flight.flight_no,
            Flight.departure_airport,
            Flight.arrival_airport,
            Flight.scheduled_departure,
            Flight.scheduled_arrival,
            Flight.status,
            Aircraft.model.label("aircraft_model"),
            Aircraft.range.label("aircraft_range"),
            Aircraft.class_.label("aircraft_class"),
        )
        .join(Aircraft, Flight.aircraft_code == Aircraft.code)
    )

    if origins:
        stmt = stmt.where(Flight.departure_airport.in_(origins))
    if destinations:
        stmt = stmt.where(Flight.arrival_airport.in_(destinations))
    if min_departure:
        stmt = stmt.where(Flight.scheduled_departure >= min_departure)
    if max_departure:
        stmt = stmt.where(Flight.scheduled_departure <= max_departure)
    if aircraft_classes:
        stmt = stmt.where(Aircraft.class_.in_(aircraft_classes))
    if min_range is not None:
        stmt = stmt.where(Aircraft.range >= min_range)
    if statuses:
        stmt = stmt.where(Flight.status.in_(statuses))
    if hour_range:
        stmt = stmt.where(sa.between(sa.func.extract("hour", Flight.scheduled_departure), hour_range[0], hour_range[1]))
    if cursor:
        stmt = stmt.where(sa.tuple_(Flight.scheduled_departure, Flight.flight_id) > cursor)

    stmt = stmt.order_by(Flight.scheduled_departure.asc(), Flight.flight_id.asc()).limit(limit)
    res = await session.execute(stmt)
    return [FacetedFlightResult(*row) for row in res.all()]

# HQ12: High-Volume Batch Upsert (2,500 Records with Conflict Resolution)
async def hq12_batch_upsert(session: AsyncSession, batch: List[dict]) -> int:
    stmt = pg_insert(FlightStatusUpdate).values(batch)
    stmt = stmt.on_conflict_do_update(
        index_elements=[FlightStatusUpdate.flight_id],
        set_={
            "status": stmt.excluded.status,
            "actual_departure": stmt.excluded.actual_departure,
            "actual_arrival": stmt.excluded.actual_arrival,
            "update_ts": stmt.excluded.update_ts,
            "version": FlightStatusUpdate.version + 1,
        },
    )
    res = await session.execute(stmt)
    await session.commit()
    return res.rowcount

# HQ13: Optimistic Concurrency Bulk Fare & Status Adjustment
async def hq13_optimistic_concurrency(session: AsyncSession) -> int:
    stmt = (
        sa.update(Flight)
        .where(
            sa.between(Flight.flight_id, 1000, 1050),
            Flight.version == 1,
        )
        .values(
            status="Boarding",
            version=Flight.version + 1,
            update_ts=sa.func.clock_timestamp(),
        )
        .returning(Flight.flight_id, Flight.version)
    )
    res = await session.execute(stmt)
    await session.commit()
    return len(res.all())

# HQ14: High-Concurrency Seat Allocation Under Contention (FOR UPDATE)
async def hq14_seat_allocation(session: AsyncSession, flight_id: int, passenger_name: str = "Test Flyer") -> bool:
    async with session.begin():
        sel_stmt = (
            sa.select(FlightSeatInventory)
            .where(
                FlightSeatInventory.flight_id == flight_id,
                FlightSeatInventory.status == "AVAILABLE",
            )
            .with_for_update()
            .limit(1)
        )
        seat = (await session.scalars(sel_stmt)).first()
        if seat:
            seat.status = "RESERVED"
            seat.passenger_name = passenger_name
            seat.reserved_at = datetime.now()
            seat.version += 1
            return True
        return False

# HQ15: Distributed Financial / Points Transfer with Serialization Retry
async def hq15_points_transfer_with_retry(
    session_factory,
    from_id: int,
    to_id: int,
    points: int,
    max_retries: int = 5,
) -> bool:
    for attempt in range(max_retries):
        async with session_factory() as session:
            try:
                async with session.begin():
                    # Set serializable isolation level
                    await session.execute(sa.text("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE"))
                    
                    stmt1 = (
                        sa.update(FrequentFlyer)
                        .where(FrequentFlyer.frequent_flyer_id == from_id)
                        .values(award_points=FrequentFlyer.award_points - points)
                    )
                    stmt2 = (
                        sa.update(FrequentFlyer)
                        .where(FrequentFlyer.frequent_flyer_id == to_id)
                        .values(award_points=FrequentFlyer.award_points + points)
                    )
                    await session.execute(stmt1)
                    await session.execute(stmt2)
                return True
            except Exception as e:
                err_str = str(e).lower()
                if "40001" in err_str or "could not serialize access" in err_str:
                    await asyncio.sleep(0.005 * (2 ** attempt))
                    continue
                raise
    return False

# HQ16: Multi-Modal Hybrid Vector Similarity + BM25 RRF Search
async def hq16_hybrid_search(
    session: AsyncSession,
    target_code: str = "LHR",
    query_text: str = "London Heathrow international hub",
) -> List[HybridAirportResult]:
    text_cte = (
        sa.select(
            Airport.airport_code,
            sa.func.row_number().over(
                order_by=sa.desc(
                    sa.func.ts_rank_cd(
                        sa.text("search_tsv"),
                        sa.func.plainto_tsquery("english", query_text),
                    )
                )
            ).label("rank_text"),
        )
        .where(sa.text(f"search_tsv @@ plainto_tsquery('english', '{query_text}')"))
        .limit(25)
        .cte("text_ranking")
    )

    vec_cte = (
        sa.select(
            Airport.airport_code,
            sa.func.row_number().over(
                order_by=sa.text(
                    f"(embedding <=> (SELECT embedding FROM postgres_air.airport WHERE airport_code = '{target_code}')) ASC"
                )
            ).label("rank_vec"),
        )
        .limit(25)
        .cte("vector_ranking")
    )

    stats_cte = (
        sa.select(
            Flight.departure_airport.label("airport_code"),
            sa.func.count().label("active_flights_count"),
        )
        .where(
            Flight.scheduled_departure >= sa.text("'2024-07-01 00:00:00+00'::timestamptz"),
            Flight.scheduled_departure < sa.text("'2024-07-08 00:00:00+00'::timestamptz"),
        )
        .group_by(Flight.departure_airport)
        .cte("airport_stats")
    )

    code_col = sa.func.coalesce(text_cte.c.airport_code, vec_cte.c.airport_code)
    rrf_score = sa.func.round(
        sa.cast(
            sa.func.coalesce(1.0 / (60 + text_cte.c.rank_text), 0.0) +
            sa.func.coalesce(1.0 / (60 + vec_cte.c.rank_vec), 0.0),
            sa.Numeric,
        ),
        5,
    ).label("rrf_score")

    joined = (
        text_cte.join(vec_cte, text_cte.c.airport_code == vec_cte.c.airport_code, full=True)
        .join(Airport, Airport.airport_code == code_col)
        .join(stats_cte, stats_cte.c.airport_code == code_col, isouter=True)
    )

    stmt = (
        sa.select(
            code_col.label("airport_code"),
            Airport.airport_name,
            Airport.city,
            sa.func.coalesce(stats_cte.c.active_flights_count, 0).label("active_flights_count"),
            rrf_score,
        )
        .select_from(joined)
        .order_by(sa.desc(sa.literal_column("rrf_score")))
        .limit(25)
    )
    res = await session.execute(stmt)
    return [HybridAirportResult(*row) for row in res.all()]
