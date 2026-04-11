// Chirp Break Timer - Background Service Worker

const DEFAULT_SETTINGS = {
  workMinutes: 20,
  breakSeconds: 20,
  breaksEnabled: true,
  blinkReminderMinutes: 10,
  blinkEnabled: true,
};

let state = {
  status: 'working', // working | onBreak | paused
  remainingSeconds: 0,
  totalSeconds: 0,
  breaksTaken: 0,
};

// Initialize
chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.local.get('settings', (result) => {
    const settings = result.settings || DEFAULT_SETTINGS;
    chrome.storage.local.set({ settings });
    if (settings.breaksEnabled) {
      startWorkTimer(settings.workMinutes);
    }
  });
});

// Start on browser launch
chrome.runtime.onStartup.addListener(() => {
  chrome.storage.local.get('settings', (result) => {
    const settings = result.settings || DEFAULT_SETTINGS;
    if (settings.breaksEnabled) {
      startWorkTimer(settings.workMinutes);
    }
  });
});

function startWorkTimer(minutes) {
  state.status = 'working';
  state.totalSeconds = minutes * 60;
  state.remainingSeconds = state.totalSeconds;
  updateBadge();

  chrome.alarms.clear('breakTimer');
  chrome.alarms.clear('tick');
  chrome.alarms.create('tick', { periodInMinutes: 1 / 60 }); // tick every second
  chrome.alarms.create('breakTimer', { delayInMinutes: minutes });
}

function startBreak(seconds) {
  state.status = 'onBreak';
  state.totalSeconds = seconds;
  state.remainingSeconds = seconds;
  updateBadge();

  // Show notification
  chrome.notifications.create('breakNotification', {
    type: 'basic',
    iconUrl: 'icons/icon128.png',
    title: 'Eye Break',
    message: 'Look at something 20 feet away for 20 seconds.',
    priority: 2,
  });

  // Tell content script to show overlay
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, {
        type: 'SHOW_BREAK',
        seconds: seconds,
      });
    }
  });

  chrome.alarms.clear('breakTimer');
  chrome.alarms.create('breakEnd', { delayInMinutes: seconds / 60 });
}

function endBreak() {
  state.breaksTaken++;
  chrome.storage.local.get('settings', (result) => {
    const settings = result.settings || DEFAULT_SETTINGS;
    startWorkTimer(settings.workMinutes);
  });

  // Tell content script to hide overlay
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, { type: 'HIDE_BREAK' });
    }
  });
}

// Alarm handler
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'breakTimer') {
    chrome.storage.local.get('settings', (result) => {
      const settings = result.settings || DEFAULT_SETTINGS;
      startBreak(settings.breakSeconds);
    });
  } else if (alarm.name === 'breakEnd') {
    endBreak();
  } else if (alarm.name === 'tick') {
    if (state.remainingSeconds > 0) {
      state.remainingSeconds--;
      updateBadge();
    }
  } else if (alarm.name === 'blinkReminder') {
    chrome.notifications.create('blinkNotification', {
      type: 'basic',
      iconUrl: 'icons/icon128.png',
      title: 'Chirp',
      message: 'Remember to blink.',
      priority: 1,
    });
  }
});

function updateBadge() {
  const minutes = Math.floor(state.remainingSeconds / 60);
  const text = state.status === 'paused' ? '||'
    : state.status === 'onBreak' ? `${state.remainingSeconds}s`
    : `${minutes}m`;

  const color = state.status === 'onBreak' ? '#22c55e'
    : state.status === 'paused' ? '#f59e0b'
    : '#9B7EC8';

  chrome.action.setBadgeText({ text });
  chrome.action.setBadgeBackgroundColor({ color });
}

// Message handler from popup/content
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case 'GET_STATE':
      sendResponse(state);
      break;
    case 'PAUSE':
      state.status = 'paused';
      chrome.alarms.clear('tick');
      chrome.alarms.clear('breakTimer');
      updateBadge();
      sendResponse(state);
      break;
    case 'RESUME':
      state.status = 'working';
      chrome.alarms.create('tick', { periodInMinutes: 1 / 60 });
      chrome.alarms.create('breakTimer', { delayInMinutes: state.remainingSeconds / 60 });
      updateBadge();
      sendResponse(state);
      break;
    case 'SKIP_BREAK':
      if (state.status === 'onBreak') {
        chrome.alarms.clear('breakEnd');
        endBreak();
      }
      sendResponse(state);
      break;
    case 'START_BREAK_NOW':
      chrome.storage.local.get('settings', (result) => {
        const settings = result.settings || DEFAULT_SETTINGS;
        startBreak(settings.breakSeconds);
        sendResponse(state);
      });
      return true; // async response
  }
});
