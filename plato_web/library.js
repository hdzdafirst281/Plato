import { exercisesData } from './exercises_data.js';
import { createIcons, Dumbbell, Play, Search, Info, Activity, X } from 'lucide';
import { inject } from '@vercel/analytics';

// Initialize Vercel Analytics
inject();

const removeAccents = (str) => {
  let result = str;
  const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  for (let i = 0; i < withDiacritics.length; i++) {
    result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
  }
  return result;
};

document.addEventListener('DOMContentLoaded', () => {
  const grid = document.getElementById('exercise-grid');
  const searchInput = document.getElementById('search-input');
  const clearSearchBtn = document.getElementById('clear-search');
  const countSpan = document.getElementById('exercise-count');
  
  // Modal Elements
  const modal = document.getElementById('exercise-modal');
  const modalBackdrop = document.getElementById('modal-backdrop');
  const modalClose = document.getElementById('modal-close');
  const modalImage = document.getElementById('modal-image');
  const modalTitle = document.getElementById('modal-title');
  const modalMuscle = document.getElementById('modal-muscle');
  const modalEquipment = document.getElementById('modal-equipment');
  const modalSecondaryMuscles = document.getElementById('modal-secondary-muscles');
  const modalInstructions = document.getElementById('modal-instructions');

  let searchQuery = '';
  let selectedMuscles = [];
  let selectedEquipments = [];
  let searchTimeout = null;

  // Populate Filters
  const muscles = [...new Set(exercisesData.map(ex => ex.primaryMuscleVi))].sort();
  const equipments = [...new Set(exercisesData.map(ex => ex.equipmentVi))].sort();

  function setupCustomDropdown(wrapperId, optionsList, selectedState, placeholder, onUpdate) {
    const wrapper = document.getElementById(wrapperId);
    const btn = wrapper.querySelector('button');
    const textSpan = btn.querySelector('span');
    const menu = wrapper.querySelector('div.filter-menu');
    const iconSvg = btn.querySelector('.dropdown-arrow');

    iconSvg.addEventListener('click', (e) => {
      if (selectedState.length > 0) {
        e.stopPropagation();
        selectedState.length = 0;
        const checkboxes = menu.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(cb => cb.checked = false);
        
        textSpan.textContent = placeholder;
        iconSvg.innerHTML = '<path d="m6 9 6 6 6-6"/>';
        iconSvg.classList.remove('is-clear', 'text-red-400');
        
        onUpdate();
      }
    });

    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      // Đóng tất cả các menu khác đang mở
      document.querySelectorAll('.filter-menu').forEach(m => {
        if (m !== menu) m.classList.add('hidden');
      });
      menu.classList.toggle('hidden');
    });

    optionsList.forEach(opt => {
      const label = document.createElement('label');
      label.className = 'flex items-center gap-3 p-2 hover:bg-white/5 rounded-lg cursor-pointer transition-colors';
      label.innerHTML = `
        <input type="checkbox" value="${opt}" class="w-4 h-4 rounded border-gray-300 text-plato-primary focus:ring-plato-primary bg-white/5 cursor-pointer">
        <span class="text-sm font-medium text-gray-200">${opt}</span>
      `;
      const checkbox = label.querySelector('input');
      checkbox.addEventListener('change', (e) => {
        if (e.target.checked) {
          selectedState.push(opt);
        } else {
          selectedState.splice(selectedState.indexOf(opt), 1);
        }
        
        if (selectedState.length === 0) {
          textSpan.textContent = placeholder;
          iconSvg.innerHTML = '<path d="m6 9 6 6 6-6"/>';
          iconSvg.classList.remove('is-clear', 'text-red-400');
        } else {
          if (selectedState.length === 1) {
            textSpan.textContent = selectedState[0];
          } else {
            textSpan.textContent = `Đã chọn (${selectedState.length})`;
          }
          iconSvg.innerHTML = '<path d="M18 6 6 18" /><path d="m6 6 12 12" />';
          iconSvg.classList.add('is-clear');
        }
        onUpdate();
      });
      menu.appendChild(label);
    });

    document.addEventListener('click', (e) => {
      if (!wrapper.contains(e.target)) {
        menu.classList.add('hidden');
      }
    });
  }

  setupCustomDropdown('muscle-filter-wrapper', muscles, selectedMuscles, 'Tất cả nhóm cơ', renderExercises);
  setupCustomDropdown('equipment-filter-wrapper', equipments, selectedEquipments, 'Tất cả dụng cụ', renderExercises);

  function renderExercises() {
    let filtered = exercisesData;

    if (searchQuery) {
      const q = removeAccents(searchQuery.toLowerCase()).trim();
      const tokens = q.split(/\s+/).filter(e => e.length > 0);
      filtered = filtered.filter(ex => {
        const normalizedName = removeAccents(ex.name.toLowerCase());
        const normalizedMuscle = removeAccents(ex.primaryMuscleVi.toLowerCase());
        const haystack = `${normalizedName} ${normalizedMuscle}`;
        return tokens.length === 0 || tokens.every(t => haystack.includes(t));
      });
    }

    if (selectedMuscles.length > 0) {
      filtered = filtered.filter(ex => selectedMuscles.includes(ex.primaryMuscleVi));
    }

    if (selectedEquipments.length > 0) {
      filtered = filtered.filter(ex => selectedEquipments.includes(ex.equipmentVi));
    }

    countSpan.textContent = filtered.length;

    grid.innerHTML = '';
    
    if (filtered.length === 0) {
      grid.innerHTML = `
        <div class="col-span-full text-center py-12 text-gray-400">
          Không tìm thấy bài tập nào phù hợp.
        </div>
      `;
      return;
    }

    filtered.forEach(ex => {
      const card = document.createElement('div');
      card.className = "exercise-card group";
      card.innerHTML = `
        <div class="relative w-full aspect-square bg-white flex items-center justify-center overflow-hidden shrink-0">
          <img src="${ex.image || '/logo_plato.png'}" alt="${ex.name}" class="w-full h-full object-contain transition-transform duration-700 group-hover:scale-105" data-img="${ex.image}" data-gif="${ex.gif}">
        </div>
        <div class="p-6 flex-1 flex flex-col">
          <h3 class="text-xl font-bold text-gray-100 exercise-title mb-4 line-clamp-2 group-hover:text-plato-primary transition-colors leading-tight">${ex.name}</h3>
          <div class="flex flex-wrap gap-2 mt-auto">
            <span class="px-3 py-1.5 bg-plato-primary/10 text-plato-primary border border-plato-primary/20 rounded-lg text-xs font-bold uppercase tracking-wider">${ex.primaryMuscleVi}</span>
            <span class="px-3 py-1.5 bg-white/5 text-gray-300 border border-white/10 rounded-lg text-xs font-bold uppercase tracking-wider flex items-center gap-1.5 equipment-tag">
              <i data-lucide="dumbbell" class="w-3.5 h-3.5 opacity-70"></i> ${ex.equipmentVi}
            </span>
          </div>
        </div>
      `;
      
      const imgEl = card.querySelector('img');
      card.addEventListener('mouseenter', () => {
        if (ex.gif) imgEl.src = ex.gif;
      });
      card.addEventListener('mouseleave', () => {
        if (ex.image) imgEl.src = ex.image;
      });

      card.addEventListener('click', () => openModal(ex));
      
      grid.appendChild(card);
    });

    // Re-initialize lucide icons for new elements
    createIcons({
      icons: { Dumbbell, Play }
    });
  }

  function openModal(ex) {
    modalTitle.textContent = ex.name;
    modalImage.src = ex.gif || ex.image || '/logo_plato.png';
    modalMuscle.textContent = ex.primaryMuscleVi;
    modalEquipment.textContent = ex.equipmentVi;
    
    modalSecondaryMuscles.innerHTML = '';
    if (ex.secondaryMuscles && ex.secondaryMuscles.length > 0) {
      ex.secondaryMuscles.forEach(m => {
        const span = document.createElement('span');
        span.className = 'px-3 py-1 bg-white/5 text-gray-300 rounded-full text-xs border border-white/10';
        span.textContent = m;
        modalSecondaryMuscles.appendChild(span);
      });
    } else {
      modalSecondaryMuscles.innerHTML = '<span class="text-gray-500 text-sm italic">Không có</span>';
    }

    modalInstructions.textContent = ex.instructions || "Không có hướng dẫn.";

    modal.classList.remove('hidden');
    // Allow display block to apply before animating opacity
    requestAnimationFrame(() => {
      modal.classList.remove('opacity-0', 'pointer-events-none');
      document.getElementById('modal-content').classList.remove('scale-95');
      document.getElementById('modal-content').classList.add('scale-100');
    });
    document.body.style.overflow = 'hidden'; // Prevent background scrolling
  }

  function closeModal() {
    modal.classList.add('opacity-0', 'pointer-events-none');
    document.getElementById('modal-content').classList.remove('scale-100');
    document.getElementById('modal-content').classList.add('scale-95');
    
    setTimeout(() => {
      modal.classList.add('hidden');
      modalImage.src = '';
      document.body.style.overflow = '';
    }, 300);
  }

  // Event Listeners
  searchInput.addEventListener('input', (e) => {
    const val = e.target.value;
    if (val) {
      clearSearchBtn.classList.remove('hidden');
    } else {
      clearSearchBtn.classList.add('hidden');
    }
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
      searchQuery = val;
      renderExercises();
    }, 300);
  });

  clearSearchBtn.addEventListener('click', () => {
    searchInput.value = '';
    searchQuery = '';
    clearSearchBtn.classList.add('hidden');
    renderExercises();
  });

  modalClose.addEventListener('click', closeModal);
  modalBackdrop.addEventListener('click', closeModal);

  // Initial render
  renderExercises();
});
