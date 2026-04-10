// Popup UI logic

function formatTime(seconds) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0');
  const s = (seconds % 60).toString().padStart(2, '0');
  return `${m}:${s}`;
}

function updateUI(state) {
  const timeEl = document.getElementById('statusTime');
  const labelEl = document.getElementById('statusLabel');
  const stateEl = document.getElementById('statusState');
  const pauseBtn = document.getElementById('pauseBtn');
  const breakBtn = document.getElementById('breakBtn');
  const breakCount = document.getElementById('breakCount');

  timeEl.textContent = formatTime(state.remainingSeconds);
  breakCount.textContent = state.breaksTaken;

  stateEl.className = 'status-state ' + state.status;

  switch (state.status) {
    case 'working':
      labelEl.textContent = 'Next break in';
      stateEl.textContent = 'Working';
      pauseBtn.textContent = 'Pause';
      breakBtn.textContent = 'Break Now';
      break;
    case 'onBreak':
      labelEl.textContent = 'Break time';
      stateEl.textContent = 'On Break';
      pauseBtn.textContent = 'Pause';
      breakBtn.textContent = 'Skip';
      break;
    case 'paused':
      labelEl.textContent = 'Paused';
      stateEl.textContent = 'Paused';
      pauseBtn.textContent = 'Resume';
      breakBtn.textContent = 'Break Now';
      break;
  }
}

// Load state
chrome.runtime.sendMessage({ type: 'GET_STATE' }, updateUI);

// Refresh every second
setInterval(() => {
  chrome.runtime.sendMessage({ type: 'GET_STATE' }, updateUI);
}, 1000);

// Pause/Resume
document.getElementById('pauseBtn').addEventListener('click', () => {
  chrome.runtime.sendMessage({ type: 'GET_STATE' }, (state) => {
    const action = state.status === 'paused' ? 'RESUME' : 'PAUSE';
    chrome.runtime.sendMessage({ type: action }, updateUI);
  });
});

// Break Now / Skip
document.getElementById('breakBtn').addEventListener('click', () => {
  chrome.runtime.sendMessage({ type: 'GET_STATE' }, (state) => {
    const action = state.status === 'onBreak' ? 'SKIP_BREAK' : 'START_BREAK_NOW';
    chrome.runtime.sendMessage({ type: action }, updateUI);
  });
});

// Toggles
document.getElementById('breaksToggle').addEventListener('change', (e) => {
  chrome.storage.local.get('settings', (result) => {
    const settings = result.settings || {};
    settings.breaksEnabled = e.target.checked;
    chrome.storage.local.set({ settings });
  });
});

document.getElementById('blinkToggle').addEventListener('change', (e) => {
  chrome.storage.local.get('settings', (result) => {
    const settings = result.settings || {};
    settings.blinkEnabled = e.target.checked;
    chrome.storage.local.set({ settings });
  });
});

// Load toggle state
chrome.storage.local.get('settings', (result) => {
  const settings = result.settings || {};
  document.getElementById('breaksToggle').checked = settings.breaksEnabled !== false;
  document.getElementById('blinkToggle').checked = settings.blinkEnabled !== false;
});
