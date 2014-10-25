local SECOND = 1
local MINUTE = 60 * SECOND
local HOUR = 60 * MINUTE
local DAY = 24 * HOUR
local WEEK = 7 * DAY
local MONTH = 30.4375 * DAY
local QUARTER = 13 * WEEK
local YEAR = 12 * MONTH
local units = {
  seconds = SECOND,
  minutes = MINUTE,
  hours = HOUR,
  days = DAY,
  weeks = WEEK,
  months = MONTH,
  quarters = QUARTER,
  years = YEAR
}
local seconds
seconds = function(spec)
  local time = 0
  for unit, value in pairs(spec) do
    if units[unit] then
      time = time + (units[unit] * (value or 0))
    end
  end
  return time
end
return {
  SECOND = SECOND,
  MINUTE = MINUTE,
  HOUR = HOUR,
  DAY = DAY,
  WEEK = WEEK,
  MONTH = MONTH,
  QUARTER = QUARTER,
  YEAR = YEAR,
  seconds = seconds
}
