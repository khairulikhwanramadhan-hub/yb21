const fs = require("fs");
const path = require("path");
const axios = require("axios");
const cheerio = require("cheerio");

module.exports = async (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ error: "id required" });

  const file = path.join(process.cwd(), "data.json");
  const list = JSON.parse(fs.readFileSync(file, "utf-8"));
  const item = list.find(i => i.id === id);
  if (!item) return res.status(404).json({ error: "not found" });

  const { data } = await axios.get(item.link, {
    headers: { "User-Agent": "Mozilla/5.0" }
  });

  const $ = cheerio.load(data);
  res.json({
    title: item.title,
    description: $("meta[name='description']").attr("content") || "",
    poster: $("meta[property='og:image']").attr("content") || "",
    genre: $("a[href*='/genre/']").first().text() || "general",
    iframe: $("iframe").attr("src") || null
  });
};
