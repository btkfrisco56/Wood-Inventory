const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const crypto = require('crypto');
const db = require('../db');

const UPLOADS_DIR = path.join(__dirname, '..', 'public', 'uploads');

function deletePhotoFile(photoPath) {
  if (!photoPath) return;
  const filename = path.basename(photoPath);
  const filePath = path.join(UPLOADS_DIR, filename);
  fs.unlink(filePath, () => {});
}

const router = express.Router();

const storage = multer.diskStorage({
  destination: UPLOADS_DIR,
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, crypto.randomUUID() + ext);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (/^image\//.test(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});

// GET /api/wood - list all records
router.get('/', (req, res) => {
  const rows = db.prepare('SELECT * FROM wood ORDER BY created_at DESC').all();
  res.json(rows);
});

// GET /api/wood/:id - get one record
router.get('/:id', (req, res) => {
  const row = db.prepare('SELECT * FROM wood WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: 'Not found' });
  res.json(row);
});

// POST /api/wood - create a record
router.post('/', upload.single('photo'), (req, res) => {
  const { species, width, thickness, length, quantity, condition, source, notes } = req.body;
  if (!species || !species.trim()) {
    return res.status(400).json({ error: 'species is required' });
  }
  const photo = req.file ? `/uploads/${req.file.filename}` : null;
  const result = db.prepare(`
    INSERT INTO wood (species, width, thickness, length, quantity, condition, source, notes, photo)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    species.trim(),
    width ? parseFloat(width) : null,
    thickness ? parseFloat(thickness) : null,
    length ? parseFloat(length) : null,
    quantity ? parseInt(quantity, 10) : 1,
    condition || null,
    source || null,
    notes || null,
    photo
  );
  const created = db.prepare('SELECT * FROM wood WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(created);
});

// PUT /api/wood/:id - update a record
router.put('/:id', upload.single('photo'), (req, res) => {
  const existing = db.prepare('SELECT * FROM wood WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Not found' });

  const { species, width, thickness, length, quantity, condition, source, notes } = req.body;
  if (!species || !species.trim()) {
    return res.status(400).json({ error: 'species is required' });
  }
  const photo = req.file ? `/uploads/${req.file.filename}` : existing.photo;

  // Delete old photo file when a new one is uploaded
  if (req.file && existing.photo) {
    deletePhotoFile(existing.photo);
  }

  db.prepare(`
    UPDATE wood
    SET species=?, width=?, thickness=?, length=?, quantity=?, condition=?, source=?, notes=?, photo=?,
        updated_at=datetime('now')
    WHERE id=?
  `).run(
    species.trim(),
    width ? parseFloat(width) : null,
    thickness ? parseFloat(thickness) : null,
    length ? parseFloat(length) : null,
    quantity ? parseInt(quantity, 10) : 1,
    condition || null,
    source || null,
    notes || null,
    photo,
    req.params.id
  );
  const updated = db.prepare('SELECT * FROM wood WHERE id = ?').get(req.params.id);
  res.json(updated);
});

// DELETE /api/wood/:id - delete a record
router.delete('/:id', (req, res) => {
  const existing = db.prepare('SELECT * FROM wood WHERE id = ?').get(req.params.id);
  if (!existing) return res.status(404).json({ error: 'Not found' });
  db.prepare('DELETE FROM wood WHERE id = ?').run(req.params.id);
  deletePhotoFile(existing.photo);
  res.status(204).send();
});

module.exports = router;
