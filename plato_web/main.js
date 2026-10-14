import AOS from 'aos';
import 'aos/dist/aos.css';
import { createIcons, Download, ChevronRight, ChevronLeft, CheckCircle, Smartphone, Moon, Sun, Menu, X, Activity, Target, Shield, ArrowRight, MessageCircle, Music, Globe, Star, Calendar, BarChart2, Zap, Dumbbell, Play, Search, Info, ArrowUp } from 'lucide';

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

const initAOS = () => {
  AOS.init({
    duration: 650,
    once: true,
    offset: 20,
    disable: () => prefersReducedMotion.matches,
  });
};

document.addEventListener('DOMContentLoaded', () => {
  const loader = document.getElementById('global-loader');
  initAOS();
  if (loader) {
    requestAnimationFrame(() => loader.classList.add('opacity-0'));
    setTimeout(() => loader.classList.add('hidden'), 300);
  }
});

window.addEventListener('load', () => {
  AOS.refresh();
}, { once: true });

window.addEventListener('pageshow', (event) => {
  if (event.persisted) {
    AOS.refreshHard();
  }
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
  });
}

// Mobile Menu Toggle
const mobileMenuBtn = document.getElementById('mobile-menu-btn');
const mobileMenu = document.getElementById('mobile-menu');
const navbar = document.getElementById('navbar');

if (mobileMenuBtn && mobileMenu) {
  mobileMenuBtn.setAttribute('aria-expanded', 'false');
  mobileMenuBtn.setAttribute('aria-controls', 'mobile-menu');
  mobileMenuBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    mobileMenu.classList.toggle('hidden');
    mobileMenu.classList.toggle('flex');
    mobileMenuBtn.setAttribute('aria-expanded', String(!mobileMenu.classList.contains('hidden')));
  });

  // Click outside to close mobile menu
  document.addEventListener('click', (e) => {
    if (!mobileMenu.classList.contains('hidden')) {
      if (!navbar.contains(e.target)) {
        mobileMenu.classList.add('hidden');
        mobileMenu.classList.remove('flex');
        mobileMenuBtn.setAttribute('aria-expanded', 'false');
      }
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

  if (isPaused && carouselToggle) {
    carouselToggle.setAttribute('aria-pressed', 'true');
    carouselToggle.setAttribute('aria-label', 'Tiếp tục trình chiếu');
    document.getElementById('carousel-toggle-text').textContent = 'Tiếp tục';
    document.getElementById('carousel-pause-icon').classList.add('hidden');
    document.getElementById('carousel-play-icon').classList.remove('hidden');
  }

  const showSlide = (index) => {
    const nextImage = slides[index];
    if (nextImage.dataset.src) {
      nextImage.src = nextImage.dataset.src;
      delete nextImage.dataset.src;
    }
    slides.forEach((slide, i) => {
      slide.setAttribute('aria-hidden', String(i !== index));
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
    showSlide(currentSlide);
  };

  const prevSlide = () => {
    currentSlide = (currentSlide - 1 + slides.length) % slides.length;
    showSlide(currentSlide);
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
    carouselToggle.setAttribute('aria-pressed', String(isPaused));
    carouselToggle.setAttribute('aria-label', isPaused ? 'Tiếp tục trình chiếu' : 'Tạm dừng trình chiếu');
    document.getElementById('carousel-toggle-text').textContent = isPaused ? 'Tiếp tục' : 'Tạm dừng';
    document.getElementById('carousel-pause-icon').classList.toggle('hidden', isPaused);
    document.getElementById('carousel-play-icon').classList.toggle('hidden', !isPaused);
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
  startAutoSlide();

  document.addEventListener('visibilitychange', () => {
    clearInterval(slideInterval);
    if (!document.hidden) startAutoSlide();
  });
}

// Scroll to Top Logic
const scrollToTopBtn = document.getElementById('scrollToTopBtn');
if (scrollToTopBtn) {
  let scrollTicking = false;
  window.addEventListener('scroll', () => {
    if (scrollTicking) return;
    scrollTicking = true;
    requestAnimationFrame(() => {
      const isVisible = window.scrollY > 300;
      scrollToTopBtn.classList.toggle('opacity-0', !isVisible);
      scrollToTopBtn.classList.toggle('pointer-events-none', !isVisible);
      scrollToTopBtn.classList.toggle('translate-y-10', !isVisible);
      scrollToTopBtn.classList.toggle('opacity-100', isVisible);
      scrollToTopBtn.classList.toggle('translate-y-0', isVisible);
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
