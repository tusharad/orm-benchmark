package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "boarding_pass", schema = "postgres_air")
public class BoardingPass {
    @Id
    @Column(name = "pass_id")
    private Integer passId;

    @Column(name = "passenger_id")
    private Long passengerId;

    @Column(name = "booking_leg_id")
    private Long bookingLegId;

    @Column(name = "seat")
    private String seat;

    @Column(name = "boarding_time")
    private Instant boardingTime;

    @Column(name = "update_ts")
    private Instant updateTs;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_leg_id", referencedColumnName = "booking_leg_id", insertable = false, updatable = false)
    private BookingLeg bookingLeg;

    public BoardingPass() {}

    public Integer getPassId() { return passId; }
    public void setPassId(Integer passId) { this.passId = passId; }

    public Long getPassengerId() { return passengerId; }
    public void setPassengerId(Long passengerId) { this.passengerId = passengerId; }

    public Long getBookingLegId() { return bookingLegId; }
    public void setBookingLegId(Long bookingLegId) { this.bookingLegId = bookingLegId; }

    public String getSeat() { return seat; }
    public void setSeat(String seat) { this.seat = seat; }

    public Instant getBoardingTime() { return boardingTime; }
    public void setBoardingTime(Instant boardingTime) { this.boardingTime = boardingTime; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public BookingLeg getBookingLeg() { return bookingLeg; }
    public void setBookingLeg(BookingLeg bookingLeg) { this.bookingLeg = bookingLeg; }
}
