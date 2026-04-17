const router = require('express').Router();

const orders = [];

// 주문 생성
router.post('/', (req, res) => {
  const { menuId, quantity } = req.body;
  if (!menuId || !quantity) {
    return res.status(400).json({ success: false, message: 'menuId와 quantity는 필수입니다.' });
  }
  const order = {
    id: orders.length + 1,
    menuId,
    quantity,
    status: 'pending',
    createdAt: new Date().toISOString()
  };
  orders.push(order);
  res.status(201).json({ success: true, data: order });
});

// 주문 상태 조회
router.get('/:id', (req, res) => {
  const order = orders.find(o => o.id === parseInt(req.params.id));
  if (!order) return res.status(404).json({ success: false, message: '주문을 찾을 수 없습니다.' });
  res.json({ success: true, data: order });
});

module.exports = router;