import moment from 'moment-timezone';
import { IANATimezones } from 'src/constants/iana';

export function generateTimestamps(timezone = 'UTC') {
  // Get the current date in the specified timezone
  const now = moment().tz(IANATimezones[timezone]);
  
  const yesterdayStart = now.clone().subtract(1, 'day').startOf('day');
  const todayStart = now.clone().startOf('day');
  const tomorrowStart = now.clone().add(1, 'day').startOf('day');
  const currentDate = now.toDate();
  const currentDateStart = now.startOf('day').toDate();
  return {
    yesterdayStart: yesterdayStart.toDate(),
    todayStart: todayStart.toDate(),
    tomorrowStart: tomorrowStart.toDate(),

    // Also include the UTC equivalents
    yesterdayStartUTC: yesterdayStart.utc().toDate(),
    todayStartUTC: todayStart.utc().toDate(),
    tomorrowStartUTC: tomorrowStart.utc().toDate(),
    currentDate,
    currentDateStart,
  };
}

// Example usage:
// const timestamps = generateTimestamps('America/New_York');
// console.log(timestamps);
export function parseOffset(offsetString: string) {
  const [hours, minutes, seconds] = offsetString.split(':').map(Number);
  const totalMinutes = hours * 60 + minutes * (hours >= 0 ? 1 : -1);
  return totalMinutes;
}
