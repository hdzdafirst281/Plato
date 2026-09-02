import AOS from 'aos';
import 'aos/dist/aos.css';
import { createIcons, Download, ChevronRight, ChevronLeft, CheckCircle, Smartphone, Moon, Sun, Menu, X, Activity, Target, Shield, ArrowRight, MessageCircle, Music, Globe, Star, Calendar, BarChart2, Zap } from 'lucide';

// Khởi tạo AOS với một chút delay để trình duyệt kịp render trạng thái ẩn ban đầu
// Điều này ngăn chặn lỗi mất animation (trình duyệt bỏ qua transition) khi load trang quá nhanh
const initAOS = () => {
  AOS.init({
    duration: 800,
    once: true,
    offset: 20,
  });
  setTimeout(() => AOS.refresh(), 100);
};

// Đợi DOM load xong, chờ 300ms để trang ổn định rồi mới bắt đầu animation
document.addEventListener('DOMContentLoaded', () => {
  const loader = document.getElementById('global-loader');
  setTimeout(() => {
    if (loader) {
      loader.classList.add('opacity-0');
      // Chờ transition opacity kết thúc rồi ẩn hẳn loader
      setTimeout(() => {
        loader.classList.add('hidden');
      }, 300);
    }
    initAOS();
  }, 300);
});

window.addEventListener('load', () => {
  setTimeout(() => AOS.refresh(), 1000);
});

window.addEventListener('pageshow', (event) => {
  if (event.persisted) {
    // Nếu load từ bộ nhớ đệm bfcache (do bấm Back/Forward hoặc chuyển trang quá nhanh)
    // Cần reset lại class aos-animate để ép animation chạy lại từ đầu
    setTimeout(() => {
      document.querySelectorAll('.aos-animate').forEach(el => {
        el.classList.remove('aos-animate');
      });
      AOS.refreshHard();
      initAOS();
    }, 300);
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
    Zap
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
  themeToggleBtn.addEventListener('click', () => {
    document.documentElement.classList.toggle('light-mode');
    
    // Save to localStorage
    const isLight = document.documentElement.classList.contains('light-mode');
    localStorage.setItem('theme', isLight ? 'light' : 'dark');
    
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

if (mobileMenuBtn && mobileMenu) {
  mobileMenuBtn.addEventListener('click', () => {
    mobileMenu.classList.toggle('hidden');
    mobileMenu.classList.toggle('flex');
  });
}

// Image Carousel Logic
const slides = document.querySelectorAll('.carousel-slide');
const prevBtn = document.getElementById('prev-slide');
const nextBtn = document.getElementById('next-slide');

if (slides.length > 0 && prevBtn && nextBtn) {
  let currentSlide = 0;
  let slideInterval;

  const showSlide = (index) => {
    slides.forEach((slide, i) => {
      if (i === index) {
        slide.classList.remove('opacity-0');
        slide.classList.add('opacity-100');
      } else {
        slide.classList.remove('opacity-100');
        slide.classList.add('opacity-0');
      }
    });
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

  // Start the slideshow automatically
  startAutoSlide();
}
