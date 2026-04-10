// Content script — injects break overlay into web pages

let overlay = null;
let countdownInterval = null;

function createOverlay(seconds) {
  removeOverlay();

  overlay = document.createElement('div');
  overlay.id = 'blink-break-overlay';

  const remaining = { value: seconds };

  overlay.innerHTML = `
    <div class="blink-break-content">
      <div class="blink-break-icon">👁</div>
      <h2>Eye Break</h2>
      <p>Look at something 20 feet away</p>
      <div class="blink-break-timer">${formatTime(remaining.value)}</div>
      <button class="blink-break-skip">Skip</button>
    </div>
  `;

  document.body.appendChild(overlay);

  // Skip button
  overlay.querySelector('.blink-break-skip').addEventListener('click', () => {
    chrome.runtime.sendMessage({ type: 'SKIP_BREAK' });
    removeOverlay();
  });

  // Countdown
  countdownInterval = setInterval(() => {
    remaining.value--;
    const timerEl = overlay?.querySelector('.blink-break-timer');
    if (timerEl) {
      timerEl.textContent = formatTime(remaining.value);
    }
    if (remaining.value <= 0) {
      removeOverlay();
    }
  }, 1000);
}

function removeOverlay() {
  if (countdownInterval) {
    clearInterval(countdownInterval);
    countdownInterval = null;
  }
  if (overlay) {
    overlay.remove();
    overlay = null;
  }
}

function formatTime(s) {
  const m = Math.floor(s / 60).toString().padStart(2, '0');
  const sec = (s % 60).toString().padStart(2, '0');
  return `${m}:${sec}`;
}

// Listen for messages from background
chrome.runtime.onMessage.addListener((message) => {
  if (message.type === 'SHOW_BREAK') {
    createOverlay(message.seconds);
  } else if (message.type === 'HIDE_BREAK') {
    removeOverlay();
  }
});
