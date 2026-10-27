import { exercisesData } from './exercises_data.js';

const PAGE_SIZE = 12;

const removeAccents = (value) => value
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/đ/g, 'd')
  .replace(/Đ/g, 'D');

const searchIndex = new Map(exercisesData.map((exercise) => [
  exercise.id,
  removeAccents(`${exercise.name} ${exercise.primaryMuscleVi}`).toLowerCase(),
]));
const exercisesById = new Map(exercisesData.map((exercise) => [exercise.id, exercise]));
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

document.addEventListener('DOMContentLoaded', () => {
  const grid = document.getElementById('exercise-grid');
  const loadSentinel = document.getElementById('load-sentinel');
  const loadStatus = document.getElementById('load-status');
  const searchInput = document.getElementById('search-input');
  const clearSearchBtn = document.getElementById('clear-search');
  const countSpan = document.getElementById('exercise-count');

  const modal = document.getElementById('exercise-modal');
  const modalBackdrop = document.getElementById('modal-backdrop');
  const modalClose = document.getElementById('modal-close');
  const modalContent = document.getElementById('modal-content');
  const modalImage = document.getElementById('modal-image');
  const modalTitle = document.getElementById('modal-title');
  const modalMuscle = document.getElementById('modal-muscle');
  const modalEquipment = document.getElementById('modal-equipment');
  const modalSecondaryMuscles = document.getElementById('modal-secondary-muscles');
  const modalInstructions = document.getElementById('modal-instructions');

  let searchQuery = '';
  const selectedMuscles = [];
  const selectedEquipments = [];
  let filteredExercises = exercisesData;
  let renderedCount = 0;
  let searchTimeout;
  let lastFocusedElement;

  function setCardPreview(card, shouldPlay) {
    const image = card.querySelector('img[data-gif-src]');
    if (!image?.dataset.gifSrc) return;

    shouldPlay = shouldPlay && !prefersReducedMotion.matches;
    const nextSource = shouldPlay ? image.dataset.gifSrc : image.dataset.staticSrc;
    card.classList.toggle('is-previewing', shouldPlay);
    if (image.getAttribute('src') !== nextSource) image.src = nextSource;
  }

  const previewObserver = !prefersReducedMotion.matches
    && window.matchMedia('(hover: none), (pointer: coarse)').matches
    && 'IntersectionObserver' in window
    ? new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          entry.target.dataset.previewVisible = String(entry.isIntersecting);
          setCardPreview(entry.target, entry.isIntersecting);
        });
      }, { rootMargin: '160px 0px', threshold: 0.15 })
    : null;

  const muscles = [...new Set(exercisesData.map((exercise) => exercise.primaryMuscleVi))].sort();
  const equipments = [...new Set(exercisesData.map((exercise) => exercise.equipmentVi))].sort();

  function updateDropdownLabel(textSpan, iconSvg, selectedState, placeholder) {
    textSpan.textContent = selectedState.length === 0
      ? placeholder
      : selectedState.length === 1
        ? selectedState[0]
        : `Đã chọn (${selectedState.length})`;
    iconSvg.innerHTML = selectedState.length === 0
      ? '<path d="m6 9 6 6 6-6"/>'
      : '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>';
    iconSvg.classList.toggle('is-clear', selectedState.length > 0);
  }

  function setupCustomDropdown(wrapperId, optionsList, selectedState, placeholder) {
    const wrapper = document.getElementById(wrapperId);
    const button = wrapper.querySelector('button');
    const textSpan = button.querySelector('span');
    const menu = wrapper.querySelector('.filter-menu');
    const iconSvg = button.querySelector('.dropdown-arrow');
    let closeTimer;

    const closeMenu = () => {
      clearTimeout(closeTimer);
      wrapper.classList.remove('is-open');
      menu.classList.remove('is-open');
      button.setAttribute('aria-expanded', 'false');
      closeTimer = setTimeout(() => {
        menu.classList.add('hidden');
        menu.classList.remove('flex');
      }, prefersReducedMotion.matches ? 0 : 180);
    };

    const openMenu = () => {
      clearTimeout(closeTimer);
      menu.classList.remove('hidden');
      menu.classList.add('flex');
      requestAnimationFrame(() => {
        wrapper.classList.add('is-open');
        menu.classList.add('is-open');
      });
      button.setAttribute('aria-expanded', 'true');
    };

    iconSvg.addEventListener('click', (event) => {
      if (selectedState.length === 0) return;
      event.stopPropagation();
      selectedState.length = 0;
      menu.querySelectorAll('input[type="checkbox"]').forEach((checkbox) => {
        checkbox.checked = false;
      });
      updateDropdownLabel(textSpan, iconSvg, selectedState, placeholder);
      renderExercises();
    });

    button.addEventListener('click', (event) => {
      event.stopPropagation();
      document.querySelectorAll('.filter-menu').forEach((otherMenu) => {
        if (otherMenu !== menu) {
          otherMenu.classList.remove('is-open');
          otherMenu.classList.add('hidden');
          otherMenu.classList.remove('flex');
          otherMenu.closest('[id$="-filter-wrapper"]')?.classList.remove('is-open');
          otherMenu.parentElement?.querySelector('button')?.setAttribute('aria-expanded', 'false');
        }
      });
      menu.classList.contains('is-open') ? closeMenu() : openMenu();
    });

    const optionsFragment = document.createDocumentFragment();
    optionsList.forEach((option) => {
      const label = document.createElement('label');
      label.className = 'flex items-center gap-3 p-2 hover:bg-white/5 rounded-lg cursor-pointer transition-colors';
      label.innerHTML = `
        <input type="checkbox" value="${option}" class="w-4 h-4 rounded border-gray-300 text-plato-primary focus:ring-plato-primary bg-white/5 cursor-pointer">
        <span class="text-sm font-medium text-gray-200">${option}</span>
      `;
      label.querySelector('input').addEventListener('change', (event) => {
        if (event.target.checked) {
          selectedState.push(option);
        } else {
          selectedState.splice(selectedState.indexOf(option), 1);
        }
        updateDropdownLabel(textSpan, iconSvg, selectedState, placeholder);
        renderExercises();
      });
      optionsFragment.appendChild(label);
    });
    menu.appendChild(optionsFragment);

    document.addEventListener('click', (event) => {
      if (!wrapper.contains(event.target)) {
        closeMenu();
      }
    });
  }

  function createExerciseCard(exercise, index) {
    const card = document.createElement('button');
    card.type = 'button';
    card.className = 'exercise-card group text-left w-full';
    card.dataset.exerciseId = exercise.id;
    card.style.setProperty('--card-delay', `${Math.min(index % PAGE_SIZE, 5) * 45}ms`);
    card.setAttribute('aria-label', `Xem hướng dẫn bài tập ${exercise.name}`);
    card.innerHTML = `
      <span class="relative w-full aspect-square bg-white flex items-center justify-center overflow-hidden shrink-0 exercise-media">
        <img src="${exercise.image || '/logo_plato.png'}" alt="Minh họa bài tập ${exercise.name}" width="480" height="480" ${index < 4 ? 'fetchpriority="high"' : 'loading="lazy"'} decoding="async" class="w-full h-full object-contain transition-transform duration-700 group-hover:scale-105" data-static-src="${exercise.image || '/logo_plato.png'}" data-gif-src="${exercise.gif || ''}">
        ${exercise.gif ? '<span class="exercise-preview-badge"><svg aria-hidden="true" viewBox="0 0 24 24"><polygon points="6 3 20 12 6 21 6 3"/></svg>Xem chuyển động</span>' : ''}
      </span>
      <span class="p-5 flex-1 flex flex-col">
        <span class="text-lg font-bold text-gray-100 exercise-title mb-4 line-clamp-2 group-hover:text-plato-primary transition-colors leading-tight">${exercise.name}</span>
        <span class="flex flex-wrap gap-2 mt-auto">
          <span class="px-3 py-1.5 bg-plato-primary/10 text-plato-primary border border-plato-primary/20 rounded-lg text-xs font-bold uppercase tracking-wider">${exercise.primaryMuscleVi}</span>
          <span class="px-3 py-1.5 bg-white/5 text-gray-300 border border-white/10 rounded-lg text-xs font-bold uppercase tracking-wider inline-flex items-center gap-1.5 equipment-tag">
            <svg aria-hidden="true" viewBox="0 0 24 24" class="w-3.5 h-3.5 opacity-70" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m6.5 6.5 11 11"/><path d="m21 21-1-1"/><path d="m3 3 1 1"/><path d="m18 22 4-4"/><path d="m2 6 4-4"/><path d="m3 10 7-7"/><path d="m14 21 7-7"/></svg>
            ${exercise.equipmentVi}
          </span>
        </span>
      </span>
    `;
    return card;
  }

  function updateLoadStatus() {
    const hasMore = renderedCount < filteredExercises.length;
    loadStatus.textContent = filteredExercises.length > 0
      ? `Đã tải ${renderedCount}/${filteredExercises.length} bài tập`
      : '';
    loadSentinel.classList.toggle('hidden', !hasMore);
  }

  function loadNextBatch() {
    if (renderedCount >= filteredExercises.length) return;
    const nextExercises = filteredExercises.slice(renderedCount, renderedCount + PAGE_SIZE);
    const fragment = document.createDocumentFragment();
    const newCards = [];
    nextExercises.forEach((exercise, index) => {
      const card = createExerciseCard(exercise, renderedCount + index);
      card.classList.add('card-enter');
      fragment.appendChild(card);
      newCards.push(card);
      if (previewObserver && exercise.gif) previewObserver.observe(card);
    });
    grid.appendChild(fragment);
    requestAnimationFrame(() => newCards.forEach((card) => card.classList.add('is-visible')));
    renderedCount += nextExercises.length;
    updateLoadStatus();
  }

  const loadObserver = 'IntersectionObserver' in window
    ? new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) loadNextBatch();
      }, { rootMargin: '600px 0px' })
    : null;

  if (loadObserver) loadObserver.observe(loadSentinel);

  function renderExercises() {
    const queryTokens = removeAccents(searchQuery.toLowerCase()).trim().split(/\s+/).filter(Boolean);
    filteredExercises = exercisesData.filter((exercise) => (
      queryTokens.every((token) => searchIndex.get(exercise.id).includes(token))
      && (selectedMuscles.length === 0 || selectedMuscles.includes(exercise.primaryMuscleVi))
      && (selectedEquipments.length === 0 || selectedEquipments.includes(exercise.equipmentVi))
    ));

    countSpan.textContent = filteredExercises.length;
    previewObserver?.disconnect();
    grid.replaceChildren();
    renderedCount = 0;

    if (filteredExercises.length === 0) {
      const emptyState = document.createElement('div');
      emptyState.className = 'col-span-full text-center py-16 px-6 rounded-3xl border border-dashed border-white/15 bg-white/[0.03]';
      emptyState.innerHTML = '<p class="text-lg font-bold text-gray-200 mb-2">Không tìm thấy bài tập phù hợp</p><p class="text-gray-400">Hãy thử tên bài tập, nhóm cơ hoặc bỏ bớt bộ lọc.</p>';
      grid.appendChild(emptyState);
      updateLoadStatus();
      return;
    }

    loadNextBatch();
    if (!loadObserver) {
      while (renderedCount < filteredExercises.length) loadNextBatch();
    }
  }

  function openModal(exercise) {
    lastFocusedElement = document.activeElement;
    modalTitle.textContent = exercise.name;
    modalImage.src = (prefersReducedMotion.matches ? exercise.image : exercise.gif) || exercise.image || '/logo_plato.png';
    modalImage.alt = `Minh họa chuyển động ${exercise.name}`;
    modalMuscle.textContent = exercise.primaryMuscleVi;
    modalEquipment.textContent = exercise.equipmentVi;
    modalSecondaryMuscles.replaceChildren();

    if (exercise.secondaryMuscles?.length) {
      const fragment = document.createDocumentFragment();
      exercise.secondaryMuscles.forEach((muscle) => {
        const span = document.createElement('span');
        span.className = 'px-3 py-1 bg-white/5 text-gray-300 rounded-full text-xs border border-white/10';
        span.textContent = muscle;
        fragment.appendChild(span);
      });
      modalSecondaryMuscles.appendChild(fragment);
    } else {
      modalSecondaryMuscles.innerHTML = '<span class="text-gray-500 text-sm italic">Không có</span>';
    }

    modalInstructions.textContent = exercise.instructions || 'Không có hướng dẫn.';
    modal.classList.remove('hidden');
    requestAnimationFrame(() => {
      modal.classList.add('is-open');
      modal.classList.remove('opacity-0', 'pointer-events-none');
      modalContent.classList.replace('scale-95', 'scale-100');
      modalClose.focus();
    });
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    modal.classList.remove('is-open');
    modal.classList.add('opacity-0', 'pointer-events-none');
    modalContent.classList.replace('scale-100', 'scale-95');
    setTimeout(() => {
      modal.classList.add('hidden');
      modalImage.removeAttribute('src');
      document.body.style.overflow = '';
      lastFocusedElement?.focus();
    }, prefersReducedMotion.matches ? 0 : 320);
  }

  setupCustomDropdown('muscle-filter-wrapper', muscles, selectedMuscles, 'Tất cả nhóm cơ');
  setupCustomDropdown('equipment-filter-wrapper', equipments, selectedEquipments, 'Tất cả dụng cụ');

  grid.addEventListener('click', (event) => {
    const card = event.target.closest('.exercise-card');
    if (card) openModal(exercisesById.get(card.dataset.exerciseId));
  });

  if (window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
    grid.addEventListener('mouseover', (event) => {
      const card = event.target.closest('.exercise-card');
      if (!card || card.contains(event.relatedTarget)) return;
      setCardPreview(card, true);
    });
    grid.addEventListener('mouseout', (event) => {
      const card = event.target.closest('.exercise-card');
      if (!card || card.contains(event.relatedTarget)) return;
      const remainsVisible = card.dataset.previewVisible === 'true' && !prefersReducedMotion.matches;
      setCardPreview(card, remainsVisible);
    });
  }

  grid.addEventListener('focusin', (event) => {
    const card = event.target.closest('.exercise-card');
    if (card) setCardPreview(card, true);
  });

  grid.addEventListener('focusout', (event) => {
    const card = event.target.closest('.exercise-card');
    if (!card) return;
    const remainsVisible = card.dataset.previewVisible === 'true' && !prefersReducedMotion.matches;
    setCardPreview(card, remainsVisible);
  });

  prefersReducedMotion.addEventListener('change', (event) => {
    if (!event.matches) return;
    grid.querySelectorAll('.exercise-card').forEach((card) => setCardPreview(card, false));
  });

  searchInput.addEventListener('input', (event) => {
    const value = event.target.value;
    clearSearchBtn.classList.toggle('hidden', !value);
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      searchQuery = value;
      renderExercises();
    }, 250);
  });

  clearSearchBtn.addEventListener('click', () => {
    searchInput.value = '';
    searchQuery = '';
    clearSearchBtn.classList.add('hidden');
    searchInput.focus();
    renderExercises();
  });

  modalClose.addEventListener('click', closeModal);
  modalBackdrop.addEventListener('click', closeModal);
  document.addEventListener('keydown', (event) => {
    if (modal.classList.contains('hidden')) return;
    if (event.key === 'Escape') closeModal();
    if (event.key === 'Tab') {
      event.preventDefault();
      modalClose.focus();
    }
  });

  renderExercises();
});
