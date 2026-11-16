package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "flight_status_update", schema = "postgres_air")
public class FlightStatusUpdate {
    @Id
    @Column(name = "flight_id")
    private Integer flightId;

    @Column(name = "status")
    private String status;

    @Column(name = "actual_departure")
    private Instant actualDeparture;

    @Column(name = "actual_arrival")
    private Instant actualArrival;

    @Column(name = "update_ts")
    private Instant updateTs;

    @Version
    @Column(name = "version")
    private Integer version;

    public FlightStatusUpdate() {}

    public FlightStatusUpdate(Integer flightId, String status, Instant actualDeparture,
                              Instant actualArrival, Instant updateTs, Integer version) {
        this.flightId = flightId;
        this.status = status;
        this.actualDeparture = actualDeparture;
        this.actualArrival = actualArrival;
        this.updateTs = updateTs;
        this.version = version;
    }

    public Integer getFlightId() { return flightId; }
    public void setFlightId(Integer flightId) { this.flightId = flightId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Instant getActualDeparture() { return actualDeparture; }
    public void setActualDeparture(Instant actualDeparture) { this.actualDeparture = actualDeparture; }

    public Instant getActualArrival() { return actualArrival; }
    public void setActualArrival(Instant actualArrival) { this.actualArrival = actualArrival; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }
}
