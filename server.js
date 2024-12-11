// server.js
const express = require('express');
const app = express();
const port = 6482;

let timer = {
  duration: 20 * 60, // 20 minutes in seconds
  remaining: 20 * 60,
  running: false,
  interval: null
};

app.use(express.json());
app.use(express.static('public'));

app.get('/timer', (req, res) => {
  const timerCopy = { ...timer };
  delete timerCopy.interval;
  res.json(timerCopy);
});

app.post('/start', (req, res) => {
  if (!timer.running) {
    timer.running = true;
    timer.interval = setInterval(() => {
      if (timer.remaining > 0) {
        timer.remaining--;
      } else {
        clearInterval(timer.interval);
        timer.running = false;
      }
    }, 1000);
  }
  const timerCopy = { ...timer };
  delete timerCopy.interval;
  res.json(timerCopy);
});

app.post('/pause', (req, res) => {
  if (timer.running) {
    clearInterval(timer.interval);
    timer.running = false;
  }
  const timerCopy = { ...timer };
  delete timerCopy.interval;
  res.json(timerCopy);
});

app.post('/reset', (req, res) => {
  clearInterval(timer.interval);
  timer.remaining = timer.duration;
  timer.running = false;
  const timerCopy = { ...timer };
  delete timerCopy.interval;
  res.json(timerCopy);
});

app.post('/configure', (req, res) => {
  const { duration } = req.body;
  timer.duration = duration * 60;
  timer.remaining = duration * 60;
  const timerCopy = { ...timer };
  delete timerCopy.interval;
  res.json(timerCopy);
});

// Ruta para servir index.html en la raíz
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});