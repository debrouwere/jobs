SECOND = 1
MINUTE = 60 * SECOND
HOUR = 60 * MINUTE 
DAY = 24 * HOUR
WEEK = 7 * DAY
MONTH = 30.4375 * DAY
QUARTER = 13 * WEEK
YEAR = 12 * MONTH

units =
    seconds: SECOND
    minutes: MINUTE
    hours: HOUR
    days: DAY
    weeks: WEEK
    months: MONTH
    quarters: QUARTER
    years: YEAR

seconds = (...) ->
    time = 0

    for unit, value in pairs {...}
        time += units[unit] * (value or 0)

return {
    :SECOND, :MINUTE, :HOUR, :DAY, :WEEK, :MONTH, :QUARTER, :YEAR, 
    :seconds
}