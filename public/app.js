/* Wood Inventory – frontend logic */

const API = '/api/wood';

let allRecords = [];
let deleteTargetId = null;
let currentPhotoUrl = null;  // track photo of record being edited

// ── Elements ────────────────────────────────────────────────────────────────
const grid          = document.getElementById('inventory-grid');
const emptyMsg      = document.getElementById('empty-msg');
const searchInput   = document.getElementById('search');
const modalOverlay  = document.getElementById('modal-overlay');
const modalTitle    = document.getElementById('modal-title');
const woodForm      = document.getElementById('wood-form');
const woodIdInput   = document.getElementById('wood-id');
const photoInput    = document.getElementById('photo');
const photoPreview  = document.getElementById('photo-preview');
const photoWrap     = document.getElementById('photo-preview-wrap');
const confirmOverlay = document.getElementById('confirm-overlay');

// ── Fetch helpers ────────────────────────────────────────────────────────────
async function apiFetch(path, opts = {}) {
  const res = await fetch(API + path, opts);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `HTTP ${res.status}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

// ── Render ───────────────────────────────────────────────────────────────────
function formatDims(r) {
  const parts = [];
  if (r.thickness) parts.push(`${r.thickness}″ T`);
  if (r.width)     parts.push(`${r.width}″ W`);
  if (r.length)    parts.push(`${r.length}″ L`);
  return parts.join(' × ') || '—';
}

function renderCards(records) {
  grid.innerHTML = '';
  if (!records.length) {
    emptyMsg.classList.remove('hidden');
    return;
  }
  emptyMsg.classList.add('hidden');
  records.forEach(r => {
    const card = document.createElement('div');
    card.className = 'wood-card';
    card.dataset.id = r.id;

    const imgHtml = r.photo
      ? `<img class="card-photo" src="${r.photo}" alt="${escHtml(r.species)}" loading="lazy" />`
      : `<div class="card-photo-placeholder">🪵</div>`;

    card.innerHTML = `
      ${imgHtml}
      <div class="card-body">
        <div class="card-species">${escHtml(r.species)}</div>
        <div class="card-dims">${escHtml(formatDims(r))}</div>
        ${r.condition ? `<span class="card-badge">${escHtml(r.condition)}</span>` : ''}
        <div>Qty: <span class="card-qty">${r.quantity}</span></div>
        ${r.source  ? `<div class="card-meta">Source: ${escHtml(r.source)}</div>` : ''}
        ${r.notes   ? `<div class="card-notes">${escHtml(r.notes)}</div>` : ''}
        <div class="card-meta">${new Date(r.created_at).toLocaleDateString()}</div>
      </div>
      <div class="card-actions">
        <button class="btn btn-primary btn-sm" data-action="edit">Edit</button>
        <button class="btn btn-danger  btn-sm" data-action="delete">Delete</button>
      </div>`;
    grid.appendChild(card);
  });
}

function escHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ── Load ─────────────────────────────────────────────────────────────────────
async function loadInventory() {
  allRecords = await apiFetch('');
  applyFilter();
}

function applyFilter() {
  const q = searchInput.value.trim().toLowerCase();
  if (!q) { renderCards(allRecords); return; }
  renderCards(allRecords.filter(r =>
    [r.species, r.source, r.notes, r.condition].some(f => f && f.toLowerCase().includes(q))
  ));
}

// ── Modal helpers ─────────────────────────────────────────────────────────────
function openModal(record = null) {
  woodForm.reset();
  photoWrap.classList.add('hidden');
  currentPhotoUrl = null;

  if (record) {
    modalTitle.textContent = 'Edit Wood';
    woodIdInput.value  = record.id;
    document.getElementById('species').value   = record.species  || '';
    document.getElementById('thickness').value = record.thickness != null ? record.thickness : '';
    document.getElementById('width').value     = record.width     != null ? record.width     : '';
    document.getElementById('length').value    = record.length    != null ? record.length    : '';
    document.getElementById('quantity').value  = record.quantity  != null ? record.quantity  : 1;
    document.getElementById('condition').value = record.condition || '';
    document.getElementById('source').value    = record.source    || '';
    document.getElementById('notes').value     = record.notes     || '';
    if (record.photo) {
      currentPhotoUrl = record.photo;
      photoPreview.src = record.photo;
      photoWrap.classList.remove('hidden');
    }
  } else {
    modalTitle.textContent = 'Add Wood';
    woodIdInput.value = '';
    document.getElementById('quantity').value = 1;
  }
  modalOverlay.classList.remove('hidden');
}

function closeModal() {
  modalOverlay.classList.add('hidden');
}

// ── Form submit ───────────────────────────────────────────────────────────────
woodForm.addEventListener('submit', async e => {
  e.preventDefault();
  const id = woodIdInput.value;
  const formData = new FormData(woodForm);

  // If no new photo file chosen and we already have a photo, drop the empty field
  if (!photoInput.files.length) {
    formData.delete('photo');
  }

  try {
    if (id) {
      await apiFetch(`/${id}`, { method: 'PUT', body: formData });
    } else {
      await apiFetch('', { method: 'POST', body: formData });
    }
    closeModal();
    await loadInventory();
  } catch (err) {
    alert('Error saving record: ' + err.message);
  }
});

// ── Card actions (edit / delete) via event delegation ─────────────────────────
grid.addEventListener('click', async e => {
  const btn = e.target.closest('[data-action]');
  if (!btn) return;
  const card = btn.closest('.wood-card');
  const id = parseInt(card.dataset.id, 10);

  if (btn.dataset.action === 'edit') {
    const record = allRecords.find(r => r.id === id);
    if (record) openModal(record);

  } else if (btn.dataset.action === 'delete') {
    deleteTargetId = id;
    confirmOverlay.classList.remove('hidden');
  }
});

// ── Confirm delete ────────────────────────────────────────────────────────────
document.getElementById('btn-confirm-delete').addEventListener('click', async () => {
  if (deleteTargetId == null) return;
  try {
    await apiFetch(`/${deleteTargetId}`, { method: 'DELETE' });
    confirmOverlay.classList.add('hidden');
    deleteTargetId = null;
    await loadInventory();
  } catch (err) {
    alert('Error deleting record: ' + err.message);
  }
});

document.getElementById('btn-confirm-cancel').addEventListener('click', () => {
  confirmOverlay.classList.add('hidden');
  deleteTargetId = null;
});

// ── Photo preview ─────────────────────────────────────────────────────────────
photoInput.addEventListener('change', () => {
  const file = photoInput.files[0];
  if (file) {
    const url = URL.createObjectURL(file);
    photoPreview.src = url;
    photoWrap.classList.remove('hidden');
  }
});

document.getElementById('btn-remove-photo').addEventListener('click', () => {
  photoInput.value = '';
  photoPreview.src = '';
  photoWrap.classList.add('hidden');
  currentPhotoUrl = null;
});

// ── Wiring ────────────────────────────────────────────────────────────────────
document.getElementById('btn-add').addEventListener('click', () => openModal());
document.getElementById('btn-cancel').addEventListener('click', closeModal);
modalOverlay.addEventListener('click', e => { if (e.target === modalOverlay) closeModal(); });
searchInput.addEventListener('input', applyFilter);

// ── Boot ──────────────────────────────────────────────────────────────────────
loadInventory();
