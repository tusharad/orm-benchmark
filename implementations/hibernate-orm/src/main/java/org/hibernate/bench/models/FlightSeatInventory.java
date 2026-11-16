package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "flight_seat_inventory", schema = "postgres_air")
@IdClass(FlightSeatInventoryId.class)
public class FlightSeatInventory {
    @Id
    @Column(name = "flight_id")
    private Integer flightId;

    @Id
    @Column(name = "seat_no")
    private String seatNo;

    @Column(name = "passenger_name")
    private String passengerName;

    @Column(name = "account_id")
    private Integer accountId;

    @Column(name = "reserved_at")
    private Instant reservedAt;

    @Column(name = "status")
    private String status;

    @Version
    @Column(name = "version")
    private Integer version;

    public FlightSeatInventory() {}

    public FlightSeatInventory(Integer flightId, String seatNo, String passengerName, Integer accountId,
                               Instant reservedAt, String status, Integer version) {
        this.flightId = flightId;
        this.seatNo = seatNo;
        this.passengerName = passengerName;
        this.accountId = accountId;
        this.reservedAt = reservedAt;
        this.status = status;
        this.version = version;
    }

    public Integer getFlightId() { return flightId; }
    public void setFlightId(Integer flightId) { this.flightId = flightId; }

    public String getSeatNo() { return seatNo; }
    public void setSeatNo(String seatNo) { this.seatNo = seatNo; }

    public String getPassengerName() { return passengerName; }
    public void setPassengerName(String passengerName) { this.passengerName = passengerName; }

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public Instant getReservedAt() { return reservedAt; }
    public void setReservedAt(Instant reservedAt) { this.reservedAt = reservedAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }
}
