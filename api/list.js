const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const page = parseInt(req.query.page || "1");
  const limit = parseInt(req.query.limit || "24");
  const search = (req.query.search || "").toLowerCase();

  const file = path.join(process.cwd(), "data.json");
  const raw = JSON.parse(fs.readFileSync(file, "utf-8"));

  let data = raw;
  if (search) {
    data = data.filter(i => i.title.toLowerCase().includes(search));
  }

  const start = (page - 1) * limit;
  const sliced = data.slice(start, start + limit);

  res.json({
    page,
    limit,
    total: data.length,
    data: sliced
  });
};
