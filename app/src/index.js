'use strict'
require('dd-trace').init()

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// 라우터 등록
app.use('/health', require('./routes/health'));
app.use('/api/menus', require('./routes/menus'));
app.use('/api/orders', require('./routes/orders'));

app.listen(PORT, () => {
  console.log(`Passorder API running on port ${PORT}`);
});

module.exports = app;