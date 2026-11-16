package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "flight", schema = "postgres_air")
public class Flight {
    @Id
    @Column(name = "flight_id")
    private Integer flightId;

    @Column(name = "flight_no")
    private String flightNo;

    @Column(name = "scheduled_departure")
    private Instant scheduledDeparture;

    @Column(name = "scheduled_arrival")
    private Instant scheduledArrival;

    @Column(name = "departure_airport")
    private String departureAirport;

    @Column(name = "arrival_airport")
    private String arrivalAirport;

    @Column(name = "status")
    private String status;

    @Column(name = "aircraft_code")
    private String aircraftCode;

    @Column(name = "actual_departure")
    private Instant actualDeparture;

    @Column(name = "actual_arrival")
    private Instant actualArrival;

    @Column(name = "update_ts")
    private Instant updateTs;

    @Version
    @Column(name = "version")
    private Integer version;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aircraft_code", referencedColumnName = "code", insertable = false, updatable = false)
    private Aircraft aircraft;

    public Flight() {}

    public Flight(Integer flightId, String flightNo, Instant scheduledDeparture, Instant scheduledArrival,
                  String departureAirport, String arrivalAirport, String status, String aircraftCode,
                  Instant actualDeparture, Instant actualArrival, Instant updateTs, Integer version) {
        this.flightId = flightId;
        this.flightNo = flightNo;
        this.scheduledDeparture = scheduledDeparture;
        this.scheduledArrival = scheduledArrival;
        this.departureAirport = departureAirport;
        this.arrivalAirport = arrivalAirport;
        this.status = status;
        this.aircraftCode = aircraftCode;
        this.actualDeparture = actualDeparture;
        this.actualArrival = actualArrival;
        this.updateTs = updateTs;
        this.version = version;
    }

    public Integer getFlightId() { return flightId; }
    public void setFlightId(Integer flightId) { this.flightId = flightId; }

    public String getFlightNo() { return flightNo; }
    public void setFlightNo(String flightNo) { this.flightNo = flightNo; }

    public Instant getScheduledDeparture() { return scheduledDeparture; }
    public void setScheduledDeparture(Instant scheduledDeparture) { this.scheduledDeparture = scheduledDeparture; }

    public Instant getScheduledArrival() { return scheduledArrival; }
    public void setScheduledArrival(Instant scheduledArrival) { this.scheduledArrival = scheduledArrival; }

    public String getDepartureAirport() { return departureAirport; }
    public void setDepartureAirport(String departureAirport) { this.departureAirport = departureAirport; }

    public String getArrivalAirport() { return arrivalAirport; }
    public void setArrivalAirport(String arrivalAirport) { this.arrivalAirport = arrivalAirport; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAircraftCode() { return aircraftCode; }
    public void setAircraftCode(String aircraftCode) { this.aircraftCode = aircraftCode; }

    public Instant getActualDeparture() { return actualDeparture; }
    public void setActualDeparture(Instant actualDeparture) { this.actualDeparture = actualDeparture; }

    public Instant getActualArrival() { return actualArrival; }
    public void setActualArrival(Instant actualArrival) { this.actualArrival = actualArrival; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }

    public Aircraft getAircraft() { return aircraft; }
    public void setAircraft(Aircraft aircraft) { this.aircraft = aircraft; }
}
