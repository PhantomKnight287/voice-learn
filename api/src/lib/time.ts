import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

// Extend dayjs with the plugins
dayjs.extend(utc);
dayjs.extend(timezone);

export function generateTimestamps(timezoneOffset = 0) {
  const currentDateInGMT = dayjs()
    .utcOffset(timezoneOffset)
    .subtract(1, 'day')
    .toDate(); // Yesterday adjusted by timezoneOffset
  const nextDateInGMT = dayjs().utcOffset(timezoneOffset).toDate(); // Today adjusted by timezoneOffset
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
