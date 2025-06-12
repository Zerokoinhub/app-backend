const SESSIONS_PER_DAY = 4;
const SESSION_INTERVAL_HOURS = 6;

function getTodayUTC() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}

function getNextSessionUnlockTime(lastUnlock) {
  return new Date(lastUnlock.getTime() + SESSION_INTERVAL_HOURS * 60 * 60 * 1000);
}

module.exports = {
  SESSIONS_PER_DAY,
  SESSION_INTERVAL_HOURS,
  getTodayUTC,
  getNextSessionUnlockTime
};
