package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "phone", schema = "postgres_air")
public class Phone {
    @Id
    @Column(name = "phone_id")
    private Integer phoneId;

    @Column(name = "account_id")
    private Integer accountId;

    @Column(name = "phone")
    private String phone;

    @Column(name = "phone_type")
    private String phoneType;

    @Column(name = "primary_phone")
    private Boolean primaryPhone;

    @Column(name = "update_ts")
    private Instant updateTs;

    public Phone() {}

    public Integer getPhoneId() { return phoneId; }
    public void setPhoneId(Integer phoneId) { this.phoneId = phoneId; }

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPhoneType() { return phoneType; }
    public void setPhoneType(String phoneType) { this.phoneType = phoneType; }

    public Boolean getPrimaryPhone() { return primaryPhone; }
    public void setPrimaryPhone(Boolean primaryPhone) { this.primaryPhone = primaryPhone; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }
}
