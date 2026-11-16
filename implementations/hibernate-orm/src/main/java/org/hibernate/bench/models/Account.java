package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.List;

@Entity
@Table(name = "account", schema = "postgres_air")
public class Account {
    @Id
    @Column(name = "account_id")
    private Integer accountId;

    @Column(name = "login")
    private String login;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "frequent_flyer_id")
    private Integer frequentFlyerId;

    @Column(name = "update_ts")
    private Instant updateTs;

    @Version
    @Column(name = "version")
    private Integer version;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "frequent_flyer_id", referencedColumnName = "frequent_flyer_id", insertable = false, updatable = false)
    private FrequentFlyer frequentFlyer;

    @OneToMany(mappedBy = "accountId", fetch = FetchType.LAZY)
    private List<Phone> phones;

    public Account() {}

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public String getLogin() { return login; }
    public void setLogin(String login) { this.login = login; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public Integer getFrequentFlyerId() { return frequentFlyerId; }
    public void setFrequentFlyerId(Integer frequentFlyerId) { this.frequentFlyerId = frequentFlyerId; }

    public Instant getUpdateTs() { return updateTs; }
    public void setUpdateTs(Instant updateTs) { this.updateTs = updateTs; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }

    public FrequentFlyer getFrequentFlyer() { return frequentFlyer; }
    public void setFrequentFlyer(FrequentFlyer frequentFlyer) { this.frequentFlyer = frequentFlyer; }

    public List<Phone> getPhones() { return phones; }
    public void setPhones(List<Phone> phones) { this.phones = phones; }
}
