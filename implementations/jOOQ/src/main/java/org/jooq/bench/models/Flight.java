package org.jooq.bench.models;

import java.time.Instant;

public class Flight {
    public Integer flightId;
    public String flightNo;
    public Instant scheduledDeparture;
    public Instant scheduledArrival;
    public String departureAirport;
    public String arrivalAirport;
    public String status;
    public String aircraftCode;
    public Instant actualDeparture;
    public Instant actualArrival;
    public Instant updateTs;
    public Integer version;

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
}
