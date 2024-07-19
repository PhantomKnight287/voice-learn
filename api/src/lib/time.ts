import moment from 'moment';

export function generateTimestamps(timezoneOffset = 0) {
  const currentDateInGMT = moment().utc().subtract(1, 'day').toDate(); // Yesterday at 12:00 UTC
  const nextDateInGMT = moment().utc().toDate(); // today at 12:00 UTC
  const previousDateInGMT = new Date(currentDateInGMT);
  previousDateInGMT.setUTCDate(previousDateInGMT.getUTCDate() - 1);

  return {
    currentDateInGMT,
    nextDateInGMT,
    previousDateInGMT,
  };
}

export function parseOffset(offsetString: string) {
  const [hours, minutes, seconds] = offsetString.split(':').map(Number);
  const totalMinutes = hours * 60 + minutes * (hours >= 0 ? 1 : -1);
  return totalMinutes;
}
