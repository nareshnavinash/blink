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

  el.textContent = `Detected: ${platform} — Free, open source, available everywhere.`;

  if (highlight) {
    document.querySelectorAll('.download-btn').forEach(btn => {
      if (btn.dataset.platform === highlight) {
        btn.classList.remove('btn-ghost-white');
        btn.classList.add('btn-white');
      } else {
        btn.classList.remove('btn-white');
        btn.classList.add('btn-ghost-white');
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
      document.querySelector('.nav-links')?.classList.remove('active');
    }
  });
});

// Nav scroll state — switch from dark to light after hero
(function navScrollState() {
  const nav = document.querySelector('.nav');
  const hero = document.querySelector('.hero');
  if (!nav || !hero) return;

  function onScroll() {
    const heroBottom = hero.offsetHeight;
    if (window.scrollY > heroBottom - 80) {
      nav.classList.add('nav-scrolled');
    } else {
      nav.classList.remove('nav-scrolled');
    }
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();
})();

// Scroll reveal via IntersectionObserver
(function scrollReveal() {
  if (typeof IntersectionObserver === 'undefined') {
    document.querySelectorAll('.reveal, .reveal-left, .reveal-right').forEach(el => {
      el.classList.add('visible');
    });
    return;
  }

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('.reveal, .reveal-left, .reveal-right').forEach(el => {
    observer.observe(el);
  });
})();
