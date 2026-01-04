const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const file = path.join(process.cwd(), "data.json");
  const data = JSON.parse(fs.readFileSync(file, "utf-8"));
  res.json([...new Set(data.map(i => i.genre))]);
};
