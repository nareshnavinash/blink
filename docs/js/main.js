// Mobile nav toggle
document.querySelector('.nav-toggle')?.addEventListener('click', () => {
  document.querySelector('.nav-links')?.classList.toggle('active');
});

// Platform detection for download section
(function detectPlatform() {
  const el = document.getElementById('platform-detect');
  if (!el) return;

  const ua = navigator.userAgent.toLowerCase();
  let platform = 'your platform';
  let highlight = null;

  if (ua.includes('mac')) {
    platform = 'macOS';
    highlight = 'macos';
  } else if (ua.includes('win')) {
    platform = 'Windows';
    highlight = 'windows';
  } else if (ua.includes('linux')) {
    platform = 'Linux';
    highlight = 'linux';
  } else if (ua.includes('iphone') || ua.includes('ipad')) {
    platform = 'iOS';
  } else if (ua.includes('android')) {
    platform = 'Android';
  }

  el.textContent = `Detected: ${platform}`;

  // Highlight the matching download button
  if (highlight) {
    document.querySelectorAll('.download-btn').forEach(btn => {
      if (btn.dataset.platform === highlight) {
        btn.classList.remove('btn-ghost');
        btn.classList.add('btn-primary');
      } else {
        btn.classList.remove('btn-primary');
        btn.classList.add('btn-ghost');
      }
    });
  }
})();

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      // Close mobile menu
      document.querySelector('.nav-links')?.classList.remove('active');
    }
  });
});
