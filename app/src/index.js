const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// 라우터 등록
app.use('/health', require('./routes/app/src/routes/health'));
app.use('/api/menus', require('./routes/app/src/routes/menus'));
app.use('/api/orders', require('./routes/app/src/routes/orders'));

app.listen(PORT, () => {
  console.log(`Passorder API running on port ${PORT}`);
});

module.exports = app;