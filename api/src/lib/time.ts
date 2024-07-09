import moment from 'moment';

export function generateTimestamps(timezoneOffset = 0) {
  const currentDateInGMT = moment()
    .utcOffset(timezoneOffset)
    .subtract(1, 'day')
    .toDate(); // Yesterday adjusted by timezoneOffset
  const nextDateInGMT = moment().utcOffset(timezoneOffset).toDate(); // Today adjusted by timezoneOffset
  return {
    currentDateInGMT,
    nextDateInGMT,
  };
}

export function parseOffset(offsetString: string) {
  const [hours, minutes, seconds] = offsetString.split(':').map(Number);
  const totalMinutes = hours * 60 + minutes * (hours >= 0 ? 1 : -1); 
  return totalMinutes;
}
