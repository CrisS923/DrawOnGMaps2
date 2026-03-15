const express = require("express");
const cors = require("cors");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

let drawings = [];

// health check
app.get("/", (req, res) => {
  res.send("DrawOnGMaps backend running");
});

// get all drawings
app.get("/drawings", (req, res) => {
  res.json(drawings);
});

// create drawing
app.post("/drawings", (req, res) => {
  const drawing = {
    id: Date.now(),
    ...req.body
  };

  drawings.push(drawing);
  res.json(drawing);
});

// delete drawing
app.delete("/drawings/:id", (req, res) => {
  const id = Number(req.params.id);

  drawings = drawings.filter(d => d.id !== id);

  res.json({ deleted: id });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
