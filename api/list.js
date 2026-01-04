const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const page = parseInt(req.query.page || "1");
  const limit = parseInt(req.query.limit || "24");
  const search = (req.query.search || "").toLowerCase();
  const genre = req.query.genre || null;

  const file = path.join(process.cwd(), "data.json");
  let data = JSON.parse(fs.readFileSync(file, "utf-8"));

  if (search) data = data.filter(i => i.title.toLowerCase().includes(search));
  if (genre) data = data.filter(i => i.genre === genre);

  const start = (page - 1) * limit;
  res.json({
    page,
    limit,
    total: data.length,
    data: data.slice(start, start + limit)
  });
};
