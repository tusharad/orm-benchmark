package org.hibernate.bench.models;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "aircraft", schema = "postgres_air")
public class Aircraft {
    @Id
    @Column(name = "code")
    private String code;

    @Column(name = "model")
    private String model;

    @Column(name = "range")
    private BigDecimal range;

    @Column(name = "\"class\"")
    private Integer aircraftClass;

    @Column(name = "velocity")
    private BigDecimal velocity;

    public Aircraft() {}

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public BigDecimal getRange() { return range; }
    public void setRange(BigDecimal range) { this.range = range; }

    public Integer getAircraftClass() { return aircraftClass; }
    public void setAircraftClass(Integer aircraftClass) { this.aircraftClass = aircraftClass; }

    public BigDecimal getVelocity() { return velocity; }
    public void setVelocity(BigDecimal velocity) { this.velocity = velocity; }
}
