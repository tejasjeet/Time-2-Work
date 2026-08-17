const API = "http://localhost:4000/api";
const MUMBAI = { lat: 19.076, lng: 72.8777 };

const state = {
  screen: "splash",
  tab: "home",
  onboarding: 0,
  phone: "",
  otp: "",
  name: "",
  about: "",
  role: null,
  token: "",
  user: null,
  jobs: [],
  job: null,
  radius: 5,
  category: "",
  applying: false,
  message: "",
  error: "",
  busy: false,
  chats: [],
  chat: null,
  messages: [],
  chatText: "",
  earnings: null,
  applications: [],
  draft: { title: "", description: "", category: "Labour", pay: "", workers: "1", address: "Andheri East" },
  previewJob: null,
};

function readStore(key) {
  try {
    return localStorage.getItem(key) || "";
  } catch {
    return "";
  }
}
function writeStore(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch {
    /* ignore */
  }
}
function clearStore(key) {
  try {
    localStorage.removeItem(key);
  } catch {
    /* ignore */
  }
}

function icon(name, fill = false) {
  return `<span class="material-symbols-rounded" style="${fill ? "font-variation-settings:'FILL' 1" : ""}">${name}</span>`;
}

async function api(path, opts = {}) {
  const headers = { "Content-Type": "application/json", ...(opts.headers || {}) };
  if (state.token) headers.Authorization = `Bearer ${state.token}`;
  const res = await fetch(API + path, { ...opts, headers });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(body.error?.message || body.message || `Request failed (${res.status})`);
  return body;
}

function go(screen, extra = {}) {
  Object.assign(state, extra, { screen, error: extra.error ?? "", message: extra.message ?? state.message });
  render();
}

function money(n) {
  return "₹" + Number(n || 0).toLocaleString("en-IN");
}

function km(job) {
  if (job.distanceKm != null) return Number(job.distanceKm).toFixed(1) + " KM";
  if (job.distanceMeters != null) return (job.distanceMeters / 1000).toFixed(1) + " KM";
  return job.address || "Nearby";
}

function jobCard(job) {
  const cat = typeof job.category === "object" ? job.category?.name : job.category;
  return `
    <div class="job-card" onclick="openJob('${job.id}')">
      <div class="row">
        <span class="chip">${cat || "Work"}</span>
        <span class="tiny grow" style="text-align:right">${km(job)}</span>
      </div>
      <b>${job.title}</b>
      ${job.description ? `<div class="tiny">${job.description}</div>` : ""}
      <div class="row">
        <b>${money(job.pay)}</b>
        <span class="tiny grow" style="text-align:right">${job.workersRequired || 1} needed</span>
      </div>
    </div>`;
}

function nav(active) {
  const items = [
    ["home", "home", "Home"],
    ["jobs", "work", "Jobs"],
    ["post", "add_circle", "Post"],
    ["chat", "chat_bubble", "Chat"],
    ["profile", "person", "Profile"],
  ];
  return `<nav class="nav">${items
    .map(
      ([id, ic, label]) =>
        `<button class="${active === id ? "on" : ""}" onclick="setTab('${id}')">
          <div class="pill">${icon(ic, active === id)}</div>${label}
        </button>`
    )
    .join("")}</nav>`;
}

function shell(inner, tab) {
  return `<div class="page with-nav">${inner}${nav(tab)}</div>`;
}

window.setTab = (tab) => {
  state.tab = tab;
  state.screen = "app";
  if (tab === "home" || tab === "jobs") loadJobs();
  if (tab === "chat") loadChats();
  if (tab === "profile") loadEarnings();
  render();
};

window.openJob = async (id) => {
  try {
    const body = await api(`/jobs/${id}`);
    state.job = body.job || body.data || body;
    state.message = "";
    go("job");
  } catch (e) {
    state.error = e.message;
    render();
  }
};

async function loadJobs() {
  try {
    const q = new URLSearchParams({
      lat: String(MUMBAI.lat),
      lng: String(MUMBAI.lng),
      radiusKm: String(state.radius),
    });
    if (state.category) q.set("category", state.category);
    const body = await api(`/jobs?${q}`);
    state.jobs = body.data || body.items || [];
  } catch (e) {
    state.error = e.message;
    state.jobs = [];
  }
  render();
}

async function loadChats() {
  try {
    const body = await api("/chats");
    state.chats = body.data || [];
  } catch {
    state.chats = [];
  }
  render();
}

async function loadEarnings() {
  try {
    state.earnings = await api("/earnings");
  } catch {
    state.earnings = null;
  }
  render();
}

async function loadApplications() {
  try {
    const body = await api("/applications/mine");
    state.applications = body.data || [];
  } catch {
    state.applications = [];
  }
  go("applications");
}

function screens() {
  const s = state.screen;
  if (s === "splash") return splash();
  if (s === "onboarding") return onboarding();
  if (s === "login") return login();
  if (s === "otp") return otp();
  if (s === "profileSetup") return profileSetup();
  if (s === "role") return role();
  if (s === "location") return location();
  if (s === "job") return jobDetails();
  if (s === "applications") return applications();
  if (s === "chatThread") return chatThread();
  if (s === "earnings") return earnings();
  return appShell();
}

function splash() {
  return `<div class="page"><div class="center">
    <div class="logo">${icon("work")}</div>
    <h1>Time2Work</h1>
    <p class="muted">Kaam Bhi, Rojgar Bhi, Bazar Bhi</p>
    <div class="spinner" style="margin-top:20px"></div>
  </div></div>`;
}

function onboarding() {
  const pages = [
    { ic: "location_on", t: "Work within 5 KM", h: "5 KM ke andar kaam", b: "Find nearby jobs in your mohalla. Distance only — never exact pins of other people." },
    { ic: "handshake", t: "I Can Do It", h: "Main Kar Sakta Hoon", b: "Apply in one tap. Chat after the owner accepts. Phone numbers stay private." },
    { ic: "storefront", t: "Kaam Bhi, Rojgar Bhi, Bazar Bhi", h: "Jobs today. Services & Bazar next.", b: "Post work, hire help, and grow into local services and a neighbourhood bazaar." },
  ];
  const p = pages[state.onboarding];
  const last = state.onboarding === pages.length - 1;
  return `<div class="page">
    <div class="pad" style="text-align:right"><button class="btn ghost" onclick="go('login')">Skip</button></div>
    <div class="center">
      <div class="logo" style="background:var(--chip)">${icon(p.ic)}</div>
      <h1>${p.t}</h1>
      <p class="muted">${p.h}</p>
      <p style="max-width:280px;line-height:1.4">${p.b}</p>
    </div>
    <div class="dots">${pages.map((_, i) => `<div class="dot ${i === state.onboarding ? "on" : ""}"></div>`).join("")}</div>
    <div class="pad"><button class="btn" onclick="onboardNext(${last})">${last ? "Get started / Shuru karein" : "Next / Aage"}</button></div>
  </div>`;
}

window.onboardNext = (last) => {
  if (last) go("login");
  else {
    state.onboarding += 1;
    render();
  }
};

function login() {
  return `<div class="page"><div class="pad" style="display:flex;flex-direction:column;height:100%">
    <h1>Time2Work</h1>
    <p class="muted">Kaam Bhi, Rojgar Bhi, Bazar Bhi</p>
    <div style="height:28px"></div>
    <h2>Login with mobile</h2>
    <p class="muted">Mobile se login karein</p>
    <div style="height:16px"></div>
    <div class="field">
      <label>Phone number</label>
      <input id="phone" inputmode="numeric" maxlength="10" placeholder="9999990001" value="${state.phone}" />
    </div>
    ${state.error ? `<p class="err">${state.error}</p>` : ""}
    <div class="spacer"></div>
    <button class="btn" ${state.busy ? "disabled" : ""} onclick="sendOtp()">Send OTP / OTP bhejein</button>
  </div></div>`;
}

window.sendOtp = async () => {
  const phone = (document.getElementById("phone")?.value || "").replace(/\D/g, "");
  state.phone = phone;
  if (phone.length < 10) {
    state.error = "Enter a valid 10-digit mobile number";
    render();
    return;
  }
  state.busy = true;
  render();
  try {
    await api("/auth/send-otp", { method: "POST", body: JSON.stringify({ phone }) });
    state.busy = false;
    go("otp");
  } catch (e) {
    state.busy = false;
    go("otp", { error: "" });
  }
};

function otp() {
  return `<div class="page">
    <div class="appbar"><button class="icon-btn" onclick="go('login')">${icon("arrow_back")}</button></div>
    <div class="pad" style="display:flex;flex-direction:column;height:100%">
      <h1>Enter OTP</h1>
      <p class="muted">OTP darj karein</p>
      <p style="color:var(--amber-dark);font-weight:700;margin-top:8px">Dev OTP: 123456</p>
      <div style="height:16px"></div>
      <div class="field">
        <label>OTP</label>
        <input id="otp" inputmode="numeric" maxlength="6" placeholder="123456" value="${state.otp}" />
      </div>
      ${state.error ? `<p class="err">${state.error}</p>` : ""}
      <div class="spacer"></div>
      <button class="btn" ${state.busy ? "disabled" : ""} onclick="verifyOtp()">Verify / Verify karein</button>
    </div>
  </div>`;
}

window.verifyOtp = async () => {
  const code = document.getElementById("otp")?.value || "123456";
  state.otp = code;
  state.busy = true;
  render();
  try {
    const body = await api("/auth/verify-otp", {
      method: "POST",
      body: JSON.stringify({ phone: state.phone, otp: code }),
    });
    state.token = body.token;
    state.user = body.user;
    writeStore("t2w_token", body.token);
    state.busy = false;
    if (!body.user?.name) go("profileSetup");
    else if (!body.user?.role) go("role");
    else go("location");
  } catch (e) {
    state.busy = false;
    state.error = e.message;
    render();
  }
};

function profileSetup() {
  return `<div class="page"><div class="scroll">
    <h1>Set up your profile</h1>
    <p class="muted">Apni profile banayein</p>
    <div style="height:20px"></div>
    <div class="center" style="flex:none;padding:0 0 16px">
      <div class="logo" style="border-radius:50%;border:3px solid var(--amber)">${icon("person")}</div>
      <p class="tiny">Photo placeholder</p>
    </div>
    <div class="field"><label>Full name / Poora naam</label><input id="name" placeholder="e.g. Ramesh Kumar" value="${state.name}" /></div>
    <div class="field"><label>About</label><textarea id="about" rows="3" placeholder="I do delivery and shop help">${state.about}</textarea></div>
    ${state.error ? `<p class="err">${state.error}</p>` : ""}
    <button class="btn" onclick="saveProfile()">Continue / Aage badhein</button>
  </div></div>`;
}

window.saveProfile = async () => {
  const name = document.getElementById("name")?.value.trim();
  const about = document.getElementById("about")?.value.trim();
  if (!name || name.length < 2) {
    state.error = "Please enter your name / Apna naam likhein";
    render();
    return;
  }
  try {
    const body = await api("/users/me", { method: "PATCH", body: JSON.stringify({ name, about }) });
    state.user = body.user || { ...state.user, name, about };
    go("role");
  } catch (e) {
    state.error = e.message;
    render();
  }
};

function role() {
  return `<div class="page"><div class="pad">
    <h1>How will you use Time2Work?</h1>
    <p class="muted">Aap kaise use karenge? You can switch later in Settings.</p>
    <div style="height:20px"></div>
    <div class="role-card" onclick="pickRole('worker')">
      <div class="icon-box">${icon("search")}</div>
      <div class="grow"><b>Find Work</b><div class="muted">Kaam Dhundo</div><div class="tiny">See nearby jobs and tap I Can Do It.</div></div>
      ${icon("chevron_right")}
    </div>
    <div class="role-card" onclick="pickRole('business')">
      <div class="icon-box">${icon("add_business")}</div>
      <div class="grow"><b>Post Work</b><div class="muted">Kaam Post Karo</div><div class="tiny">Hire local help. Pay a small posting fee.</div></div>
      ${icon("chevron_right")}
    </div>
  </div></div>`;
}

window.pickRole = async (role) => {
  try {
    await api("/users/me/role", { method: "POST", body: JSON.stringify({ role }) });
    state.role = role;
    if (state.user) state.user.role = role;
    go("location");
  } catch (e) {
    state.error = e.message;
    render();
  }
};

function location() {
  return `<div class="page"><div class="pad" style="display:flex;flex-direction:column;height:100%;text-align:center">
    <div class="spacer"></div>
    <div class="logo" style="background:var(--chip)">${icon("near_me")}</div>
    <h1>Enable location</h1>
    <p class="muted">Location on karein</p>
    <p style="margin-top:12px;line-height:1.4">We use your area to show jobs within 5 or 10 KM. Other people only see an approximate area — never your exact pin.</p>
    <div class="spacer"></div>
    <button class="btn" onclick="useCity()">Use Mumbai demo area</button>
    <div style="height:10px"></div>
    <button class="btn outline" onclick="useCity()">Use city default</button>
  </div></div>`;
}

window.useCity = async () => {
  try {
    await api("/users/me/location", {
      method: "POST",
      body: JSON.stringify({ lat: MUMBAI.lat, lng: MUMBAI.lng, address: "Mumbai" }),
    });
  } catch {
    /* still enter app */
  }
  state.tab = "home";
  state.screen = "app";
  await loadJobs();
};

function appShell() {
  if (state.tab === "jobs") return shell(jobsFeed(), "jobs");
  if (state.tab === "post") return shell(postJob(), "post");
  if (state.tab === "chat") return shell(chatList(), "chat");
  if (state.tab === "profile") return shell(profile(), "profile");
  return shell(home(), "home");
}

function home() {
  const name = (state.user?.name || "there").split(" ")[0];
  const nearby = state.jobs.slice(0, 5);
  return `
    <div class="appbar">
      <div class="grow">
        <h3>Namaste, ${name}<span class="sub">Kaam Bhi, Rojgar Bhi, Bazar Bhi</span></h3>
      </div>
      <button class="icon-btn">${icon("search")}</button>
      <button class="icon-btn">${icon("notifications")}</button>
    </div>
    <div class="scroll">
      <div class="search-box">${icon("search")} Search jobs, skills… / Kaam dhundo</div>
      <div class="teasers">
        <div class="teaser">${icon("handyman")}<div style="font-weight:800;margin-top:8px">Services</div><div class="tiny" style="color:#ddd">Book local help</div><div class="amber">Coming soon · Phase 2</div></div>
        <div class="teaser">${icon("storefront")}<div style="font-weight:800;margin-top:8px">Local Bazar</div><div class="tiny" style="color:#ddd">Buy & sell nearby</div><div class="amber">Coming soon · Phase 2</div></div>
      </div>
      <div class="section"><h4>Nearby jobs</h4><button onclick="setTab('jobs')">See all</button></div>
      ${state.error ? `<p class="err">${state.error}</p>` : ""}
      ${nearby.length ? nearby.map(jobCard).join("") : `<p class="muted">No jobs nearby yet. Try 10 KM.</p>`}
    </div>`;
}

function jobsFeed() {
  return `
    <div class="appbar"><h3>Jobs / Kaam</h3></div>
    <div class="filters">
      <button class="${state.radius === 5 ? "on" : ""}" onclick="setRadius(5)">5 KM</button>
      <button class="${state.radius === 10 ? "on" : ""}" onclick="setRadius(10)">10 KM</button>
    </div>
    <div class="scroll">${state.jobs.map(jobCard).join("") || `<p class="muted">No open jobs in this radius.</p>`}</div>`;
}

window.setRadius = (kmVal) => {
  state.radius = kmVal;
  loadJobs();
};

function jobDetails() {
  const job = state.job;
  if (!job) return `<div class="page"><div class="center">Missing job</div></div>`;
  const cat = typeof job.category === "object" ? job.category?.name : job.category;
  const poster = job.poster || {};
  const isOwner = state.user && (job.poster?.id === state.user.id || job.posterId === state.user.id);
  return `<div class="page">
    <div class="appbar"><button class="icon-btn" onclick="go('app')">${icon("arrow_back")}</button><h3>Job details</h3></div>
    <div class="scroll">
      <div class="row"><span class="chip">${cat || "Work"}</span><span class="tiny">${(job.status || "").toUpperCase()}</span></div>
      <h1 style="margin:10px 0 6px">${job.title}</h1>
      <h2>${money(job.pay)}</h2>
      <div class="meta">${icon("place")} ${job.address || "Approximate area nearby"}</div>
      <div class="meta">${icon("social_distance")} ${km(job)} away</div>
      <div class="meta">${icon("groups")} ${job.workersRequired || 1} worker(s) needed</div>
      <h4 style="margin:16px 0 6px">About this work</h4>
      <p>${job.description || "No extra details."}</p>
      ${poster.name ? `<div class="row" style="margin-top:16px"><div class="avatar">${poster.name[0]}</div><div><b>${poster.name}</b><div class="tiny">★ ${(job.posterRating || poster.avgRating || 0).toFixed?.(1) || job.posterRating || ""}</div></div></div>` : ""}
      ${state.message ? `<p class="ok" style="margin-top:12px">${state.message}</p>` : ""}
      ${state.error ? `<p class="err">${state.error}</p>` : ""}
      <div style="height:16px"></div>
      ${
        isOwner
          ? `<button class="btn" onclick="loadApplications()">View applications / Applications dekhein</button>`
          : `<button class="btn" ${state.applying ? "disabled" : ""} onclick="applyJob()">${icon("handshake")} I Can Do It<small>Main Kar Sakta Hoon</small></button>`
      }
    </div>
  </div>`;
}

window.applyJob = async () => {
  state.applying = true;
  render();
  try {
    await api(`/jobs/${state.job.id}/apply`, {
      method: "POST",
      body: JSON.stringify({ message: "I can do it / Main kar sakta hoon" }),
    });
    state.applying = false;
    state.message = "Applied! The owner will see you in Applications.";
    render();
  } catch (e) {
    state.applying = false;
    state.error = e.message;
    render();
  }
};

function postJob() {
  const d = state.draft;
  return `
    <div class="appbar"><h3>Post work / Kaam post karein</h3></div>
    <div class="scroll">
      <p class="muted">Tell neighbours what you need. A small posting fee is paid before it goes live.</p>
      <div style="height:12px"></div>
      <div class="field"><label>Title</label><input id="ptitle" value="${d.title}" placeholder="Need 2 helpers for shop shifting" /></div>
      <div class="field"><label>Details</label><textarea id="pdesc" rows="3">${d.description}</textarea></div>
      <div class="field"><label>Category</label><input id="pcat" value="${d.category}" /></div>
      <div class="field"><label>Pay (₹)</label><input id="ppay" inputmode="numeric" value="${d.pay}" placeholder="600" /></div>
      <div class="field"><label>Workers</label><input id="pworkers" inputmode="numeric" value="${d.workers}" /></div>
      <div class="field"><label>Area</label><input id="paddr" value="${d.address}" /></div>
      ${state.error ? `<p class="err">${state.error}</p>` : ""}
      ${state.message ? `<p class="ok">${state.message}</p>` : ""}
      <button class="btn" onclick="publishJob()">Preview & post · ₹19 fee</button>
    </div>`;
}

window.publishJob = async () => {
  const title = document.getElementById("ptitle")?.value.trim();
  const description = document.getElementById("pdesc")?.value.trim();
  const category = document.getElementById("pcat")?.value.trim() || "Labour";
  const pay = Number(document.getElementById("ppay")?.value || 0);
  const workersRequired = Number(document.getElementById("pworkers")?.value || 1);
  const address = document.getElementById("paddr")?.value.trim();
  state.draft = { title, description, category, pay, workers: String(workersRequired), address };
  if (!title || pay <= 0) {
    state.error = "Add a title and pay amount";
    render();
    return;
  }
  try {
    const created = await api("/jobs", {
      method: "POST",
      body: JSON.stringify({
        title,
        description,
        category,
        pay,
        payType: "fixed",
        workersRequired,
        address,
        lat: MUMBAI.lat,
        lng: MUMBAI.lng,
      }),
    });
    const job = created.job || created;
    await api("/payments/create-order", {
      method: "POST",
      body: JSON.stringify({ type: "job_fee", jobId: job.id, method: "mock" }),
    }).catch(() => null);
    await api(`/jobs/${job.id}/pay-fee`, { method: "POST", body: JSON.stringify({ method: "mock" }) }).catch(() => null);
    await api(`/jobs/${job.id}/publish`, { method: "POST" }).catch(() => null);
    state.message = "Job posted. Workers within 5–10 KM can see it.";
    state.error = "";
    await loadJobs();
  } catch (e) {
    state.error = e.message;
    render();
  }
};

function chatList() {
  return `
    <div class="appbar"><h3>Chat</h3></div>
    <div class="scroll">
      ${
        state.chats.length
          ? state.chats
              .map((c) => {
                const other = (c.participants || []).find((p) => p.id !== state.user?.id) || {};
                return `<div class="list-card" onclick="openChat('${c.id}')">
                  <div class="row"><div class="avatar">${(other.name || "C")[0]}</div>
                  <div class="grow"><b>${other.name || "Chat"}</b><div class="tiny">${c.lastMessage || "No messages yet"}</div></div></div>
                </div>`;
              })
              .join("")
          : `<p class="muted">Chats open after a worker is accepted. Phone numbers stay hidden.</p>`
      }
    </div>`;
}

window.openChat = async (id) => {
  state.chat = state.chats.find((c) => c.id === id) || { id };
  try {
    const body = await api(`/chats/${id}/messages`);
    state.messages = body.data || [];
  } catch {
    state.messages = [];
  }
  go("chatThread");
};

function chatThread() {
  return `<div class="page">
    <div class="appbar"><button class="icon-btn" onclick="setTab('chat')">${icon("arrow_back")}</button><h3>Chat</h3></div>
    <div class="scroll">
      ${state.messages
        .map((m) => {
          const mine = m.sender?.id === state.user?.id;
          return `<div class="chat-bubble ${mine ? "me" : "them"}">${m.text || ""}</div>`;
        })
        .join("") || `<p class="muted">Say hello. Numbers are not shared.</p>`}
    </div>
    <div class="composer">
      <input id="chatText" placeholder="Message" />
      <button onclick="sendChat()">${icon("send")}</button>
    </div>
  </div>`;
}

window.sendChat = async () => {
  const text = document.getElementById("chatText")?.value.trim();
  if (!text || !state.chat) return;
  try {
    await api(`/chats/${state.chat.id}/messages`, { method: "POST", body: JSON.stringify({ text }) });
    await openChat(state.chat.id);
  } catch (e) {
    state.error = e.message;
    render();
  }
};

function profile() {
  const u = state.user || {};
  const e = state.earnings || {};
  return `
    <div class="appbar"><h3>Profile</h3></div>
    <div class="scroll">
      <div class="row">
        <div class="avatar" style="width:64px;height:64px;font-size:24px">${(u.name || "T")[0]}</div>
        <div class="grow">
          <h2>${u.name || "Time2Work user"}</h2>
          <p class="muted">${u.role === "business" ? "Business / Job poster" : "Worker"} · ★ ${Number(u.avgRating || 0).toFixed(1)}</p>
        </div>
      </div>
      <div class="stat-grid">
        <div class="stat"><span class="tiny">Today</span><b>${money(e.today || e.todayEarnings || 0)}</b></div>
        <div class="stat"><span class="tiny">This month</span><b>${money(e.month || e.thisMonth || 0)}</b></div>
        <div class="stat"><span class="tiny">Total</span><b>${money(e.total || e.totalEarnings || 0)}</b></div>
        <div class="stat"><span class="tiny">Pending</span><b>${money(e.pending || e.pendingPayments || 0)}</b></div>
      </div>
      <div class="list-card" onclick="loadApplications()"><b>Applications</b><div class="tiny">Applied / received</div></div>
      <div class="list-card" onclick="go('earnings')"><b>Earnings & history</b><div class="tiny">Jobs, fees, payouts</div></div>
      <button class="btn outline" onclick="logout()">Log out</button>
    </div>`;
}

function earnings() {
  const e = state.earnings || {};
  return `<div class="page">
    <div class="appbar"><button class="icon-btn" onclick="go('app')">${icon("arrow_back")}</button><h3>Earnings</h3></div>
    <div class="scroll">
      <h1>${money(e.total || e.totalEarnings || 0)}</h1>
      <p class="muted">Total earnings</p>
      <div class="stat-grid">
        <div class="stat"><span class="tiny">Today</span><b>${money(e.today || 0)}</b></div>
        <div class="stat"><span class="tiny">Week</span><b>${money(e.week || e.thisWeek || 0)}</b></div>
        <div class="stat"><span class="tiny">Month</span><b>${money(e.month || 0)}</b></div>
        <div class="stat"><span class="tiny">Pending</span><b>${money(e.pending || 0)}</b></div>
      </div>
    </div>
  </div>`;
}

function applications() {
  return `<div class="page">
    <div class="appbar"><button class="icon-btn" onclick="go('app')">${icon("arrow_back")}</button><h3>Applications</h3></div>
    <div class="scroll">
      ${
        state.applications.length
          ? state.applications
              .map((a) => {
                const job = typeof a.jobId === "object" ? a.jobId : {};
                const worker = a.worker || {};
                return `<div class="list-card">
                  <b>${job.title || worker.name || "Application"}</b>
                  <div class="tiny">${a.status} ${worker.name ? "· " + worker.name : ""}</div>
                  ${
                    a.status === "applied" && state.user?.role === "business"
                      ? `<button class="btn" style="min-height:44px;margin-top:8px" onclick="decideApp('${a.id}','accepted')">Accept</button>`
                      : ""
                  }
                </div>`;
              })
              .join("")
          : `<p class="muted">No applications yet.</p>`
      }
    </div>
  </div>`;
}

window.decideApp = async (id, status) => {
  try {
    await api(`/applications/${id}`, { method: "PATCH", body: JSON.stringify({ status }) });
    await loadApplications();
  } catch (e) {
    state.error = e.message;
    render();
  }
};

window.logout = () => {
  clearStore("t2w_token");
  state.token = "";
  state.user = null;
  go("login");
};

function render() {
  document.getElementById("app").innerHTML = screens();
}

function tickClock() {
  const d = new Date();
  const el = document.getElementById("clock");
  if (el) el.textContent = d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
}

async function boot() {
  state.token = readStore("t2w_token");
  tickClock();
  setInterval(tickClock, 30000);
  render();
  setTimeout(async () => {
    if (state.token) {
      try {
        const me = await api("/auth/me");
        state.user = me.user;
        state.tab = "home";
        state.screen = "app";
        await loadJobs();
        return;
      } catch {
        clearStore("t2w_token");
        state.token = "";
      }
    }
    go("onboarding");
  }, 900);
}

boot();
