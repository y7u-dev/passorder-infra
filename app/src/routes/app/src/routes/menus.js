const router = require('express').Router();

const menus = [
  { id: 1, name: '아메리카노', price: 4500, category: 'coffee' },
  { id: 2, name: '카페라떼', price: 5000, category: 'coffee' },
  { id: 3, name: '그린티라떼', price: 5500, category: 'tea' },
];

// 전체 메뉴 조회
router.get('/', (req, res) => {
  res.json({ success: true, data: menus });
});

// 특정 메뉴 조회
router.get('/:id', (req, res) => {
  const menu = menus.find(m => m.id === parseInt(req.params.id));
  if (!menu) return res.status(404).json({ success: false, message: '메뉴를 찾을 수 없습니다.' });
  res.json({ success: true, data: menu });
});

module.exports = router;