package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "passenger", schema = "postgres_air")
public class Passenger {
    @Id
    @Column(name = "passenger_id")
    private Integer passengerId;

    @Column(name = "booking_id")
    private Integer bookingId;

    @Column(name = "booking_ref")
    private String bookingRef;

    @Column(name = "passenger_no")
    private Integer passengerNo;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "account_id")
    private Integer accountId;

    @Column(name = "update_ts")
    private Instant updateTs;

    @Column(name = "age")
    private Integer age;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", referencedColumnName = "booking_id", insertable = false, updatable = false)
    private Booking booking;

    public Passenger() {}

    public Integer getPassengerId() { return passengerId; }
    public void setPassengerId(Integer passengerId) { this.passengerId = passengerId; }

    public Integer getBookingId() { return bookingId; }
    public void setBookingId(Integer bookingId) { this.bookingId = bookingId; }

    public String getBookingRef() { return bookingRef; }
    public void setBookingRef(String bookingRef) { this.bookingRef = bookingRef; }

    public Integer getPassengerNo() { return passengerNo; }
    public void setPassengerNo(Integer passengerNo) { this.passengerNo = passengerNo; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public Integer getAge() { return age; }
    public void setAge(Integer age) { this.age = age; }

    public Booking getBooking() { return booking; }
    public void setBooking(Booking booking) { this.booking = booking; }
}
