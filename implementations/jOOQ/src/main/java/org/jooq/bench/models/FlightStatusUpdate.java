package org.jooq.bench.models;

import java.time.Instant;

public class FlightStatusUpdate {
    private Integer flightId;
    private String status;
    private Instant actualDeparture;
    private Instant actualArrival;
    private Instant updateTs;
    private Integer version;

    public FlightStatusUpdate() {}

    public FlightStatusUpdate(Integer flightId, String status, Instant actualDeparture, Instant actualArrival, Instant updateTs, Integer version) {
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
