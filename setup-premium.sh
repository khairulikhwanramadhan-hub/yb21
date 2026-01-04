#!/bin/bash

echo "🔥 SETUP YB21 PREMIUM START"

# pastiin di root project
if [ ! -f package.json ]; then
  echo "❌ package.json tidak ditemukan. Jalankan di folder project!"
  exit 1
fi

echo "📦 Install dependency..."
npm install axios cheerio

echo "📁 Setup folder..."
mkdir -p api public

echo "🧠 Generate API list (pagination + search)..."
cat > api/list.js <<'EOF'
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
EOF

echo "🧠 Generate API detail..."
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
  const desc = $("meta[name='description']").attr("content") || "";

  res.json({
    title: item.title,
    description: desc
  });
};
EOF

echo "🎨 Generate PREMIUM index.html..."
cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>YB21+</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui}
header{padding:16px;display:flex;justify-content:space-between;align-items:center}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:14px;padding:16px}
.card{background:#0f172a;border-radius:12px;padding:12px;cursor:pointer;transition:.2s}
.card:hover{transform:scale(1.03)}
input{background:#020617;border:1px solid #1e293b;color:white;padding:8px;border-radius:8px}
</style>
</head>
<body>

<header>
  <b>YB21+</b>
  <input id="q" placeholder="Cari...">
</header>

<div id="grid" class="grid"></div>

<script>
let page=1, q="";
const grid=document.getElementById("grid");

async function load(reset=false){
  if(reset){page=1;grid.innerHTML="";}
  const r=await fetch(`/api/list?page=${page}&search=${q}`);
  const j=await r.json();
  j.data.forEach(i=>{
    const d=document.createElement("div");
    d.className="card";
    d.textContent=i.title;
    d.onclick=()=>location.href="/watch.html?id="+i.id;
    grid.appendChild(d);
  });
  page++;
}

document.getElementById("q").oninput=e=>{
  q=e.target.value.toLowerCase();
  load(true);
};

window.onscroll=()=>{
  if(innerHeight+scrollY>=document.body.offsetHeight-300){
    load();
  }
};

load();
</script>
</body>
</html>
EOF

echo "🎬 Generate watch.html..."
cat > public/watch.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Watch</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{margin:0;background:#020617;color:white;font-family:system-ui;padding:20px}
a{color:#22c55e;text-decoration:none}
</style>
</head>
<body>

<a href="/">← Back</a>
<h2 id="title"></h2>
<p id="desc"></p>

<script>
const id=new URLSearchParams(location.search).get("id");
fetch("/api/detail?id="+id)
.then(r=>r.json())
.then(d=>{
  document.getElementById("title").innerText=d.title;
  document.getElementById("desc").innerText=d.description;
});
</script>

</body>
</html>
EOF

echo "✅ SETUP SELESAI"
echo "👉 Tinggal: git add . && git commit && git push"
