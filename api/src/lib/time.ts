import moment from 'moment';

export function generateTimestamps() {
  const currentDateInGMT = moment().utc().subtract(1, 'day').toDate(); // Yesterday at 12:00 UTC
  const nextDateInGMT = moment().utc().toDate(); // today at 12:00 UTC
  return {
    currentDateInGMT,
    nextDateInGMT,
  };
}
