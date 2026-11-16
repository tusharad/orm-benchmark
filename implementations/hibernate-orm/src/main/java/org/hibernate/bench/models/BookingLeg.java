package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.List;

@Entity
@Table(name = "booking_leg", schema = "postgres_air")
public class BookingLeg {
    @Id
    @Column(name = "booking_leg_id")
    private Integer bookingLegId;

    @Column(name = "booking_id")
    private Integer bookingId;

    @Column(name = "flight_id")
    private Integer flightId;

    @Column(name = "leg_num")
    private Integer legNum;

    @Column(name = "is_returning")
    private Boolean isReturning;

    @Column(name = "update_ts")
    private Instant updateTs;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "flight_id", insertable = false, updatable = false)
    private Flight flight;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", referencedColumnName = "booking_id", insertable = false, updatable = false)
    private Booking booking;

    @OneToMany(mappedBy = "bookingLeg", fetch = FetchType.LAZY)
    private List<BoardingPass> boardingPasses;

    public BookingLeg() {}

    public Integer getBookingLegId() { return bookingLegId; }
    public void setBookingLegId(Integer bookingLegId) { this.bookingLegId = bookingLegId; }

    public Integer getBookingId() { return bookingId; }
    public void setBookingId(Integer bookingId) { this.bookingId = bookingId; }

    public Integer getFlightId() { return flightId; }
    public void setFlightId(Integer flightId) { this.flightId = flightId; }

    public Integer getLegNum() { return legNum; }
    public void setLegNum(Integer legNum) { this.legNum = legNum; }

    public Boolean getIsReturning() { return isReturning; }
    public void setIsReturning(Boolean isReturning) { this.isReturning = isReturning; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public Flight getFlight() { return flight; }
    public void setFlight(Flight flight) { this.flight = flight; }

    public Booking getBooking() { return booking; }
    public void setBooking(Booking booking) { this.booking = booking; }

    public List<BoardingPass> getBoardingPasses() { return boardingPasses; }
    public void setBoardingPasses(List<BoardingPass> boardingPasses) { this.boardingPasses = boardingPasses; }
}
