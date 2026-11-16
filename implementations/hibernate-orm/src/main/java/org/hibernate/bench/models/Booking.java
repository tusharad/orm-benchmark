package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Entity
@Table(name = "booking", schema = "postgres_air")
public class Booking {
    @Id
    @Column(name = "booking_id")
    private Long bookingId;

    @Column(name = "booking_ref")
    private String bookingRef;

    @Column(name = "booking_name")
    private String bookingName;

    @Column(name = "account_id")
    private Integer accountId;

    @Column(name = "email")
    private String email;

    @Column(name = "phone")
    private String phone;

    @Column(name = "update_ts")
    private Instant updateTs;

    @Column(name = "price")
    private BigDecimal price;

    @OneToMany(mappedBy = "booking", fetch = FetchType.LAZY)
    private List<BookingLeg> bookingLegs;

    @OneToMany(mappedBy = "booking", fetch = FetchType.LAZY)
    private List<Passenger> passengers;

    public Booking() {}

    public Long getBookingId() { return bookingId; }
    public void setBookingId(Long bookingId) { this.bookingId = bookingId; }

    public String getBookingRef() { return bookingRef; }
    public void setBookingRef(String bookingRef) { this.bookingRef = bookingRef; }

    public String getBookingName() { return bookingName; }
    public void setBookingName(String bookingName) { this.bookingName = bookingName; }

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public List<BookingLeg> getBookingLegs() { return bookingLegs; }
    public void setBookingLegs(List<BookingLeg> bookingLegs) { this.bookingLegs = bookingLegs; }

    public List<Passenger> getPassengers() { return passengers; }
    public void setPassengers(List<Passenger> passengers) { this.passengers = passengers; }
}
