# Weather API Research for Mainland China Access

## Research Summary
**Date:** July 3, 2026
**Objective:** Find professional weather APIs accessible from mainland China that provide:
- Hourly cloud cover (%)
- AOD (Aerosol Optical Depth)
- Precipitation probability (%)

**Context:** Current Open-Meteo API (api.open-meteo.com) is blocked by SSL from mainland China (DW server).

---

## APIs Evaluated

### 1. QWeather (和风天气) ⭐ RECOMMENDED
**Website:** https://dev.qweather.com/en  
**China Access:** ✅ YES (Chinese company, designed for China)  
**Free Tier:** Available (requires registration)

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Real-time weather API includes `cloud` field (%) |
| Precipitation | ✅ YES | Real-time `precip`, minutely forecast (China only, 2hr), hourly/daily forecasts |
| AOD | ❌ NO | Air Quality API provides PM2.5, PM10, NO2, O3, CO, AQI - but NOT AOD |

#### Key Features:
- Real-time weather with cloud cover percentage
- Minutely precipitation forecast (next 2 hours, China only, 1km resolution)
- Hourly forecast (up to 240 hours)
- Daily forecast (up to 16 days)
- Grid weather with 3-5km resolution
- Air quality with multiple AQI standards
- Global coverage (200,000+ cities)
- JWT authentication supported
- Gzip compressed responses

#### Pricing:
- Free tier available
- Enterprise customization available
- VAT invoices supported (important for Chinese companies)

---

### 2. Weatherbit.io ⭐ RECOMMENDED
**Website:** https://www.weatherbit.io  
**China Access:** ✅ LIKELY (global API, no known China blocks)  
**Free Tier:** Available

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Daily and hourly cloud cover, plus low/mid/high cloud layers |
| Precipitation | ✅ YES | Daily, hourly, and minutely (60 min) precipitation + probability |
| AOD | ❌ NO | Air Quality API provides PM2.5, PM10, CO, NO2, SO2, O3, AQI - but NOT AOD |

#### Key Features:
- Hourly forecast: 240 hours
- Daily forecast: 16 days
- Minutely forecast: 60 minutes
- Cloud cover: total + low/mid/high layers
- Probability of precipitation
- Air quality (Business/Enterprise tier)
- 1-13km resolution globally
- Machine learning bias correction

#### Pricing:
- Free tier available
- Business/Enterprise tiers for advanced features
- Air quality requires paid tier

---

### 3. WeatherAPI.com
**Website:** https://www.weatherapi.com  
**China Access:** ⚠️ UNKNOWN (website had errors during testing)  
**Free Tier:** 1M calls/month

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Standard weather data includes cloud cover |
| Precipitation | ✅ YES | Current, forecast, historical precipitation |
| AOD | ❌ NO | Air quality data available but AOD not documented |

#### Key Features:
- Current, forecast, historical weather
- Air quality data (aqi parameter)
- 15-minute interval forecasts
- Marine weather
- Sports data
- Time zone data

#### Notes:
- Website returned errors during testing
- API explorer showed air quality option but no AOD specifics

---

### 4. Tomorrow.io
**Website:** https://www.tomorrow.io  
**China Access:** ⚠️ UNKNOWN  
**Free Tier:** Limited

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Weather API includes cloud cover |
| Precipitation | ✅ YES | Precipitation intensity and probability |
| AOD | ⚠️ MAYBE | Some documentation suggests aerosol data in premium tiers |

#### Notes:
- Documentation site timed out during testing
- Known for high-resolution weather models
- Premium tiers may include additional atmospheric data

---

### 5. Visual Crossing
**Website:** https://www.visualcrossing.com  
**China Access:** ⚠️ UNKNOWN (site timed out)  
**Free Tier:** 1000 records/day

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Historical and forecast data |
| Precipitation | ✅ YES | Comprehensive precipitation data |
| AOD | ❌ NO | Not documented in standard offerings |

#### Notes:
- Website timed out during testing
- Strong historical weather data
- Excel/Google Sheets integration

---

### 6. CMA (中国气象局 - China Meteorological Administration)
**Website:** http://www.cma.gov.cn  
**China Access:** ✅ YES (official Chinese government service)  
**Free Tier:** ⚠️ RESTRICTED

#### Data Availability:
| Parameter | Available | Notes |
|-----------|-----------|-------|
| Cloud Cover | ✅ YES | Standard weather observations |
| Precipitation | ✅ YES | Official precipitation data |
| AOD | ⚠️ MAYBE | May have aerosol data through research partnerships |

#### Notes:
- Official Chinese government meteorological service
- API access may require special permissions
- Best data quality for China locations
- May require Chinese business registration

---

## AOD Data Challenge

**Critical Finding:** AOD (Aerosol Optical Depth) is NOT commonly available in standard weather APIs.

### Alternative Sources for AOD:
1. **NASA Worldview / GIBS**
   - MODIS, VIIRS satellite AOD data
   - Free but requires processing
   - https://worldview.earthdata.nasa.gov

2. **CAMS (Copernicus Atmosphere Monitoring Service)**
   - European service with global aerosol data
   - https://atmosphere.copernicus.eu
   - May have accessibility issues from China

3. **QWeather Air Quality**
   - Provides PM2.5, PM10 (related to aerosols)
   - Not true AOD but correlated
   - Accessible from China

4. **Research APIs**
   - NASA GIOVANNI
   - ESA Earth Online
   - Typically require academic/research affiliation

---

## Recommendations

### For China Operations:

#### Primary Recommendation: **QWeather (和风天气)**
- ✅ Guaranteed China accessibility
- ✅ Cloud cover data available
- ✅ Precipitation data (including minutely for China)
- ✅ Chinese language support
- ✅ VAT invoices for business use
- ❌ No AOD (but provides PM2.5/PM10 as proxy)

#### Secondary Recommendation: **Weatherbit.io**
- ✅ Cloud cover (including layered)
- ✅ Precipitation probability
- ✅ Global coverage
- ❌ No AOD
- ⚠️ Verify China accessibility

### For AOD Data:
Since AOD is not available in standard weather APIs, consider:
1. **Use PM2.5/PM10 as proxy** (available from QWeather, Weatherbit)
2. **NASA satellite data** (free, requires processing)
3. **Research partnership** for specialized atmospheric data

---

## Implementation Notes

### QWeather Integration:
```bash
# Real-time weather (includes cloud cover)
GET https://your_api_host/v7/weather/now?location={location_id}
Authorization: Bearer *** Response includes:
{
  "now": {
    "cloud": "10",        # Cloud cover percentage
    "precip": "0.0",      # Precipitation
    "vis": "16",          # Visibility
    ...
  }
}

# Minutely precipitation (China only)
GET https://your_api_host/v7/minutely/precipitation?location={lat,lon}

# Air quality (PM2.5, PM10 - AOD proxy)
GET https://your_api_host/airquality/v1/current/{lat}/{lon}
```

### Weatherbit Integration:
```bash
# Hourly forecast (includes cloud cover, precipitation probability)
GET https://api.weatherbit.io/v2.0/forecast/hourly?lat={lat}&lon={lon}&key={key}

# Response includes:
{
  "clouds": 25,           # Cloud cover percentage
  "pop": 0,               # Probability of precipitation
  "precip": 0,            # Precipitation amount
  ...
}
```

---

## Testing from China Required

Before final selection, test these endpoints from the actual DW server in mainland China:
1. QWeather API endpoints
2. Weatherbit API endpoints
3. SSL certificate validation
4. Response times
5. Rate limiting behavior

---

## Conclusion

**No single API provides all three required parameters (cloud cover, AOD, precipitation) with guaranteed China access.**

**Best Solution:** Use QWeather for cloud cover and precipitation (guaranteed China access), and either:
- Accept PM2.5/PM10 as AOD proxy (same API)
- Integrate NASA satellite data for true AOD (separate source)

**Cost:** QWeather free tier should suffice for development; Weatherbit free tier for backup/testing.
