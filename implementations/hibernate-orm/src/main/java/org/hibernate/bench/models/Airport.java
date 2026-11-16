package org.hibernate.bench.models;

import jakarta.persistence.*;

@Entity
@Table(name = "airport", schema = "postgres_air")
public class Airport {
    @Id
    @Column(name = "airport_code")
    private String airportCode;

    @Column(name = "airport_name")
    private String airportName;

    @Column(name = "city")
    private String city;

    @Column(name = "airport_tz")
    private String airportTz;

    @Column(name = "continent")
    private String continent;

    @Column(name = "iso_country")
    private String isoCountry;

    @Column(name = "iso_region")
    private String isoRegion;

    @Column(name = "intnl")
    private Boolean intnl;

    public Airport() {}

    public String getAirportCode() { return airportCode; }
    public void setAirportCode(String airportCode) { this.airportCode = airportCode; }

    public String getAirportName() { return airportName; }
    public void setAirportName(String airportName) { this.airportName = airportName; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getAirportTz() { return airportTz; }
    public void setAirportTz(String airportTz) { this.airportTz = airportTz; }

    public String getContinent() { return continent; }
    public void setContinent(String continent) { this.continent = continent; }

    public String getIsoCountry() { return isoCountry; }
    public void setIsoCountry(String isoCountry) { this.isoCountry = isoCountry; }

    public String getIsoRegion() { return isoRegion; }
    public void setIsoRegion(String isoRegion) { this.isoRegion = isoRegion; }

    public Boolean getIntnl() { return intnl; }
    public void setIntnl(Boolean intnl) { this.intnl = intnl; }
}
