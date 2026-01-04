const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  try {
    const filePath = path.join(process.cwd(), "data.json");
    const raw = fs.readFileSync(filePath, "utf-8");
    const data = JSON.parse(raw);

    res.status(200).json({
      success: true,
      total: data.length,
      data
    });
  } catch (e) {
    res.status(500).json({
      success: false,
      error: e.message
    });
  }
};
