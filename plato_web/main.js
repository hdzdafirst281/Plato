import AOS from 'aos';
import 'aos/dist/aos.css';
import { createIcons, Download, ChevronRight, ChevronLeft, CheckCircle, Smartphone, Moon, Sun, Menu, X, Activity, Target, Shield, ArrowRight, MessageCircle, Music, Globe, Star, Calendar, BarChart2, Zap, Dumbbell, Play, Search, Info, ArrowUp } from 'lucide';

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
const motionDuration = (duration) => prefersReducedMotion.matches ? 0 : duration;

const enhanceMotionTargets = () => {
  document.querySelectorAll('.prose > section').forEach((section, index) => {
    section.dataset.aos ||= 'fade-up';
    section.dataset.aosDelay ||= String(Math.min(index, 3) * 50);
  });

  document.querySelectorAll('.bento-card:not([data-aos])').forEach((card, index) => {
    card.dataset.aos = 'fade-up';
    card.dataset.aosDelay = String(Math.min(index, 3) * 70);
  });

  document.querySelectorAll('#features img').forEach((image, index) => {
    image.classList.add('product-shot');
    image.style.setProperty('--shot-delay', `${Math.min(index % 3, 2) * 80}ms`);
    image.parentElement?.classList.add('product-visual');
  });
};

const initAOS = () => {
  enhanceMotionTargets();
  AOS.init({
    duration: 650,
    once: true,
    offset: 70,
    easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
    disable: () => prefersReducedMotion.matches,
  });
  setTimeout(() => AOS.refresh(), motionDuration(80));
};

document.addEventListener('DOMContentLoaded', () => {
  const loader = document.getElementById('global-loader');
  const startPageMotion = () => {
    document.body.classList.add('page-entered');
    if (loader) {
      loader.classList.add('is-exiting');
      setTimeout(() => loader.classList.add('hidden'), motionDuration(420));
    }
    initAOS();
  };

  requestAnimationFrame(startPageMotion);
});

window.addEventListener('load', () => {
  setTimeout(() => AOS.refresh(), 1000);
}, { once: true });

window.addEventListener('pageshow', (event) => {
  document.body.classList.remove('page-leaving');
  if (event.persisted) AOS.refreshHard();
});

// Initialize Lucide Icons
createIcons({
  icons: {
    Download,
    ChevronRight,
    ChevronLeft,
    CheckCircle,
    Smartphone,
    Moon,
    Sun,
    Menu,
    X,
    Activity,
    Target,
    Shield,
    ArrowRight,
    MessageCircle,
    Music,
    Globe,
    Star,
    Calendar,
    BarChart2,
    Zap,
    Dumbbell,
    Play,
    Search,
    Info,
    ArrowUp
  }
});

// Dark/Light mode toggle
const themeToggleBtn = document.getElementById('theme-toggle');
const iconSun = document.getElementById('icon-sun');
const iconMoon = document.getElementById('icon-moon');

// Toggle icons on load based on html class
if (document.documentElement.classList.contains('light-mode')) {
  if (iconSun && iconMoon) {
    iconSun.classList.add('hidden');
    iconMoon.classList.remove('hidden');
  }
}

if (themeToggleBtn) {
  themeToggleBtn.setAttribute('aria-pressed', String(document.documentElement.classList.contains('light-mode')));
  themeToggleBtn.addEventListener('click', () => {
    themeToggleBtn.classList.remove('is-switching');
    void themeToggleBtn.offsetWidth;
    themeToggleBtn.classList.add('is-switching');
    document.documentElement.classList.toggle('light-mode');
    
    // Save to localStorage
    const isLight = document.documentElement.classList.contains('light-mode');
    localStorage.setItem('theme', isLight ? 'light' : 'dark');
    themeToggleBtn.setAttribute('aria-pressed', String(isLight));
    
    // Toggle icons
    if (isLight) {
      iconSun.classList.add('hidden');
      iconMoon.classList.remove('hidden');
    } else {
      iconSun.classList.remove('hidden');
      iconMoon.classList.add('hidden');
    }
    setTimeout(() => themeToggleBtn.classList.remove('is-switching'), motionDuration(420));
  });
}

// Mobile Menu Toggle
const mobileMenuBtn = document.getElementById('mobile-menu-btn');
const mobileMenu = document.getElementById('mobile-menu');
const navbar = document.getElementById('navbar');

if (mobileMenuBtn && mobileMenu) {
  let mobileMenuTimer;

  const openMobileMenu = () => {
    clearTimeout(mobileMenuTimer);
    mobileMenu.classList.remove('hidden');
    mobileMenu.classList.add('flex');
    requestAnimationFrame(() => mobileMenu.classList.add('is-open'));
    mobileMenuBtn.classList.add('is-open');
    mobileMenuBtn.setAttribute('aria-expanded', 'true');
  };

  const closeMobileMenu = () => {
    clearTimeout(mobileMenuTimer);
    mobileMenu.classList.remove('is-open');
    mobileMenuBtn.classList.remove('is-open');
    mobileMenuBtn.setAttribute('aria-expanded', 'false');
    mobileMenuTimer = setTimeout(() => {
      mobileMenu.classList.add('hidden');
      mobileMenu.classList.remove('flex');
    }, motionDuration(220));
  };

  mobileMenuBtn.setAttribute('aria-expanded', 'false');
  mobileMenuBtn.setAttribute('aria-controls', 'mobile-menu');
  mobileMenuBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    mobileMenu.classList.contains('is-open') ? closeMobileMenu() : openMobileMenu();
  });

  // Click outside to close mobile menu
  document.addEventListener('click', (e) => {
    if (!mobileMenu.classList.contains('hidden')) {
      if (!navbar.contains(e.target)) {
        closeMobileMenu();
      }
    }
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !mobileMenu.classList.contains('hidden')) {
      closeMobileMenu();
      mobileMenuBtn.focus();
    }
  });
}

// Image Carousel Logic
const slides = document.querySelectorAll('.carousel-slide');
const prevBtn = document.getElementById('prev-slide');
const nextBtn = document.getElementById('next-slide');
const carouselRegion = document.getElementById('carousel-region');
const carouselToggle = document.getElementById('carousel-toggle');
const carouselStatus = document.getElementById('carousel-status');

if (slides.length > 0 && prevBtn && nextBtn) {
  let currentSlide = 0;
  let slideInterval;
  let isPaused = prefersReducedMotion.matches;

  const syncCarouselToggle = () => {
    if (!carouselToggle) return;
    carouselToggle.setAttribute('aria-pressed', String(isPaused));
    carouselToggle.setAttribute('aria-label', isPaused ? 'Tiếp tục trình chiếu' : 'Tạm dừng trình chiếu');
    document.getElementById('carousel-toggle-text').textContent = isPaused ? 'Tiếp tục' : 'Tạm dừng';
    document.getElementById('carousel-pause-icon').classList.toggle('hidden', isPaused);
    document.getElementById('carousel-play-icon').classList.toggle('hidden', !isPaused);
  };

  syncCarouselToggle();

  const showSlide = (index, direction = 1) => {
    const nextImage = slides[index];
    if (nextImage.dataset.src) {
      nextImage.src = nextImage.dataset.src;
      delete nextImage.dataset.src;
    }
    slides.forEach((slide, i) => {
      slide.setAttribute('aria-hidden', String(i !== index));
      slide.classList.toggle('from-previous', direction < 0 && i === index);
      slide.classList.toggle('is-active', i === index);
      if (i === index) {
        slide.classList.remove('opacity-0');
        slide.classList.add('opacity-100');
      } else {
        slide.classList.remove('opacity-100');
        slide.classList.add('opacity-0');
      }
    });
    if (carouselStatus) carouselStatus.textContent = `Hình ${index + 1} trên ${slides.length}`;
  };

  const nextSlide = () => {
    currentSlide = (currentSlide + 1) % slides.length;
    showSlide(currentSlide, 1);
  };

  const prevSlide = () => {
    currentSlide = (currentSlide - 1 + slides.length) % slides.length;
    showSlide(currentSlide, -1);
  };

  const startAutoSlide = () => {
    if (isPaused || document.hidden) return;
    slideInterval = setInterval(nextSlide, 3000);
  };

  const resetAutoSlide = () => {
    clearInterval(slideInterval);
    startAutoSlide();
  };

  nextBtn.addEventListener('click', () => {
    nextSlide();
    resetAutoSlide();
  });

  prevBtn.addEventListener('click', () => {
    prevSlide();
    resetAutoSlide();
  });

  carouselToggle?.addEventListener('click', () => {
    isPaused = !isPaused;
    clearInterval(slideInterval);
    syncCarouselToggle();
    if (!isPaused) startAutoSlide();
  });

  carouselRegion?.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      prevSlide();
      resetAutoSlide();
    }
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      nextSlide();
      resetAutoSlide();
    }
  });

  // Start the slideshow automatically
  showSlide(0);
  startAutoSlide();

  document.addEventListener('visibilitychange', () => {
    clearInterval(slideInterval);
    if (!document.hidden) startAutoSlide();
  });

  prefersReducedMotion.addEventListener('change', (event) => {
    if (!event.matches) return;
    isPaused = true;
    clearInterval(slideInterval);
    syncCarouselToggle();
  });
}

// Scroll to Top Logic
const scrollToTopBtn = document.getElementById('scrollToTopBtn');
if (scrollToTopBtn) {
  let scrollTicking = false;
  const updateScrollProgress = () => {
    const scrollRange = document.documentElement.scrollHeight - window.innerHeight;
    const progress = scrollRange > 0 ? Math.min(window.scrollY / scrollRange, 1) : 0;
    const isVisible = window.scrollY > 300;
    scrollToTopBtn.style.setProperty('--scroll-progress', `${progress * 360}deg`);
    scrollToTopBtn.classList.toggle('is-visible', isVisible);
    scrollToTopBtn.classList.toggle('opacity-0', !isVisible);
    scrollToTopBtn.classList.toggle('pointer-events-none', !isVisible);
    scrollToTopBtn.classList.toggle('translate-y-10', !isVisible);
    scrollToTopBtn.classList.toggle('opacity-100', isVisible);
    scrollToTopBtn.classList.toggle('translate-y-0', isVisible);
    scrollToTopBtn.setAttribute('aria-hidden', String(!isVisible));
    scrollToTopBtn.tabIndex = isVisible ? 0 : -1;
  };

  updateScrollProgress();
  window.addEventListener('scroll', () => {
    if (scrollTicking) return;
    scrollTicking = true;
    requestAnimationFrame(() => {
      updateScrollProgress();
      scrollTicking = false;
    });
  }, { passive: true });

  scrollToTopBtn.addEventListener('click', () => {
    window.scrollTo({
      top: 0,
      behavior: prefersReducedMotion.matches ? 'auto' : 'smooth'
    });
  });
}

// A short exit transition keeps navigation between static pages from feeling abrupt.
document.addEventListener('click', (event) => {
  const link = event.target.closest('a[href]');
  if (!link || prefersReducedMotion.matches || event.defaultPrevented || event.button !== 0) return;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || link.target || link.hasAttribute('download')) return;

  const destination = new URL(link.href, window.location.href);
  const isSameDocumentHash = destination.pathname === window.location.pathname
    && destination.search === window.location.search
    && destination.hash;
  if (destination.origin !== window.location.origin || isSameDocumentHash || destination.href === window.location.href) return;

  event.preventDefault();
  document.body.classList.add('page-leaving');
  setTimeout(() => window.location.assign(destination.href), 180);
});

let navbarTicking = false;
const updateNavbar = () => {
  navbar?.classList.toggle('is-scrolled', window.scrollY > 24);
  navbarTicking = false;
};
updateNavbar();
window.addEventListener('scroll', () => {
  if (navbarTicking) return;
  navbarTicking = true;
  requestAnimationFrame(updateNavbar);
}, { passive: true });
