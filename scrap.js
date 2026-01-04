const axios = require("axios");
const cheerio = require("cheerio");
const fs = require("fs");

const URL = "https://yb21.icu/";

(async () => {
  try {
    const { data } = await axios.get(URL, {
      headers: {
        "User-Agent": "Mozilla/5.0"
      },
      timeout: 15000
    });

    const $ = cheerio.load(data);
    let results = [];

    $("a").each((i, el) => {
      const title = $(el).text().trim();
      const link = $(el).attr("href");

      if (
        title &&
        link &&
        link.startsWith("http") &&
        title.length > 5
      ) {
        results.push({
          title,
          link
        });
      }
    });

    fs.writeFileSync(
      "data.json",
      JSON.stringify(results, null, 2)
    );

    console.log("✅ Scrap sukses");
    console.log("📦 Total data:", results.length);
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
})();
