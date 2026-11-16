package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "frequent_flyer", schema = "postgres_air")
public class FrequentFlyer {
    @Id
    @Column(name = "frequent_flyer_id")
    private Integer frequentFlyerId;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "title")
    private String title;

    @Column(name = "card_num")
    private String cardNum;

    @Column(name = "level")
    private Integer level;

    @Column(name = "award_points")
    private Integer awardPoints;

    @Column(name = "email")
    private String email;

    @Column(name = "phone")
    private String phone;

    @Column(name = "update_ts")
    private Instant updateTs;

    public FrequentFlyer() {}

    public Integer getFrequentFlyerId() { return frequentFlyerId; }
    public void setFrequentFlyerId(Integer frequentFlyerId) { this.frequentFlyerId = frequentFlyerId; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCardNum() { return cardNum; }
    public void setCardNum(String cardNum) { this.cardNum = cardNum; }

    public Integer getLevel() { return level; }
    public void setLevel(Integer level) { this.level = level; }

    public Integer getAwardPoints() { return awardPoints; }
    public void setAwardPoints(Integer awardPoints) { this.awardPoints = awardPoints; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }
}
