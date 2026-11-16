package org.hibernate.bench.models;

import java.io.Serializable;
import java.util.Objects;

public class FlightSeatInventoryId implements Serializable {
    private Integer flightId;
    private String seatNo;

    public FlightSeatInventoryId() {}

    public FlightSeatInventoryId(Integer flightId, String seatNo) {
        this.flightId = flightId;
        this.seatNo = seatNo;
    }

    public Integer getFlightId() { return flightId; }
    public void setFlightId(Integer flightId) { this.flightId = flightId; }

    public String getSeatNo() { return seatNo; }
    public void setSeatNo(String seatNo) { this.seatNo = seatNo; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        FlightSeatInventoryId that = (FlightSeatInventoryId) o;
        return Objects.equals(flightId, that.flightId) && Objects.equals(seatNo, that.seatNo);
    }

    @Override
    public int hashCode() {
        return Objects.hash(flightId, seatNo);
    }
}
