#!/bin/bash
set -e

echo "🔥 YB21 ALL-IN SETUP START"

# sanity check
if [ ! -f package.json ]; then
  echo "❌ package.json tidak ditemukan. Jalankan di root project."
  exit 1
fi

echo "📦 Install dependency (axios, cheerio)..."
npm install axios cheerio

echo "📁 Ensure folders..."
mkdir -p api public

echo "🧠 Write API: list.js (pagination + search + genre)..."
cat > api/list.js <<'EOF'
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
EOF

echo "🧠 Write API: detail.js (desc + poster + genre + iframe)..."
cat > api/detail.js <<'EOF'
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
EOF

echo "🧠 Write API: genres.js..."
cat > api/genres.js <<'EOF'
const fs = require("fs");
const path = require("path");

module.exports = (req, res) => {
  const file = path.join(process.cwd(), "data.json");
  const data = JSON.parse(fs.readFileSync(file, "utf-8"));
  res.json([...new Set(data.map(i => i.genre))]);
};
EOF

echo "🎨 Write NAVBAR (_nav.html)..."
cat > public/_nav.html <<'EOF'
<header class="nav">
  <div class="logo">YB21+</div>
  <nav>
    <a href="/">Home</a>
    <a href="/genre.html">Genre</a>
  </nav>
  <input id="q" placeholder="Search...">
</header>

<style>
.nav{display:flex;justify-content:space-between;align-items:center;
background:#020617;padding:14px;position:sticky;top:0}
.nav a{color:#94a3b8;margin-right:12px;text-decoration:none}
.nav a:hover{color:white}
.logo{font-weight:bold}
input{background:#020617;border:1px solid #1e293b;color:white;
padding:6px 10px;border-radius:6px}
</style>

<script>
document.getElementById("q").addEventListener("keypress",e=>{
  if(e.key==="Enter"){
    location.href="/search.html?q="+encodeURIComponent(e.target.value);
  }
});
</script>
EOF

echo "🎨 Write HOME (index.html)..."
cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>YB21+</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="manifest" href="/manifest.json">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:14px;padding:16px}
.card{background:#0f172a;border-radius:12px;padding:12px;cursor:pointer;transition:.2s}
.card:hover{transform:scale(1.03)}
</style>
</head>
<body>
<div id="nav"></div>
<div id="grid" class="grid"></div>

<script>
fetch("/_nav.html").then(r=>r.text()).then(t=>nav.innerHTML=t);
fetch("/api/list?page=1&limit=48")
.then(r=>r.json())
.then(j=>{
  j.data.forEach(i=>{
    const d=document.createElement("div");
    d.className="card";
    d.textContent=i.title;
    d.onclick=()=>location.href="/watch.html?id="+i.id;
    grid.appendChild(d);
  });
});
if('serviceWorker' in navigator){navigator.serviceWorker.register('/sw.js');}
</script>
</body>
</html>
EOF

echo "🎨 Write SEARCH (search.html)..."
cat > public/search.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Search</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:14px;padding:16px}
.card{background:#0f172a;border-radius:12px;padding:12px;cursor:pointer}
</style>
</head>
<body>
<div id="nav"></div>
<div id="grid" class="grid"></div>
<script>
fetch("/_nav.html").then(r=>r.text()).then(t=>nav.innerHTML=t);
const q=new URLSearchParams(location.search).get("q")||"";
fetch("/api/list?search="+encodeURIComponent(q))
.then(r=>r.json())
.then(j=>{
  j.data.forEach(i=>{
    const d=document.createElement("div");
    d.className="card";
    d.textContent=i.title;
    d.onclick=()=>location.href="/watch.html?id="+i.id;
    grid.appendChild(d);
  });
});
</script>
</body>
</html>
EOF

echo "🎨 Write GENRE (genre.html)..."
cat > public/genre.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Genre</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui}
a{display:block;padding:10px;color:#94a3b8;text-decoration:none}
a:hover{color:white}
</style>
</head>
<body>
<div id="nav"></div>
<div id="list"></div>
<script>
fetch("/_nav.html").then(r=>r.text()).then(t=>nav.innerHTML=t);
fetch("/api/genres").then(r=>r.json()).then(gs=>{
  gs.forEach(g=>{
    const a=document.createElement("a");
    a.href="/?genre="+g;
    a.textContent=g;
    list.appendChild(a);
  });
});
</script>
</body>
</html>
EOF

echo "🎬 Write WATCH (watch.html)..."
cat > public/watch.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Watch</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui;padding:16px}
iframe{width:100%;height:220px;border:0}
a{color:#22c55e;text-decoration:none}
</style>
</head>
<body>
<a href="/">← Back</a>
<h2 id="title">Loading...</h2>
<iframe id="player" allowfullscreen></iframe>
<p id="desc"></p>
<script>
const id=new URLSearchParams(location.search).get("id");
fetch("/api/detail?id="+id).then(r=>r.json()).then(d=>{
  document.getElementById("title").innerText=d.title||"";
  document.getElementById("desc").innerText=d.description||"";
  if(d.iframe){document.getElementById("player").src=d.iframe;}
});
</script>
</body>
</html>
EOF

echo "📱 Write PWA files..."
cat > public/manifest.json <<'EOF'
{
  "name": "YB21+",
  "short_name": "YB21+",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#020617",
  "theme_color": "#020617",
  "icons": []
}
EOF

cat > public/sw.js <<'EOF'
self.addEventListener('fetch', e => {});
EOF

echo "✅ ALL-IN SETUP DONE"
echo "👉 Next: git add . && git commit && git push"
