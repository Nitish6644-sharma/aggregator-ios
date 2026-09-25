<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>AggregatorBuddy — Wireframes v3 (Multi-select / Batch Edit)</title>
<style>
  :root{
    --bg:#FAFAF8; --card:#FFFFFF; --ink:#1C1C1E; --ink-2:#6E6E73;
    --teal:#2F6F5E; --teal-tint:#E7F0EC; --red:#C1462F; --red-tint:#FBEAE6;
    --line:#E7E5E0; --board-bg:#F0EEE9; --skeleton-a:#EFEDE8; --skeleton-b:#E3E1DB;
  }
  *{box-sizing:border-box;}
  html,body{margin:0;padding:0;background:var(--board-bg);
    font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text","SF Pro Display",Helvetica,Arial,sans-serif;
    color:var(--ink);}

  .board-header{ padding:40px 48px 8px; }
  .board-header h1{ font-size:22px; font-weight:600; margin:0 0 4px; letter-spacing:-.01em; }
  .board-header p{ margin:0; color:var(--ink-2); font-size:14px; max-width:640px; line-height:1.5; }
  .board-header .tag{ display:inline-block; margin-top:12px; font-size:11px; font-weight:700; color:var(--teal); background:var(--teal-tint); padding:5px 10px; border-radius:100px; }

  .section-label{ padding:28px 48px 0; font-size:13px; font-weight:700; color:var(--ink); }
  .section-sub{ padding:2px 48px 0; font-size:12px; color:var(--ink-2); max-width:640px; line-height:1.5; }

  .board{ display:flex; gap:34px; padding:20px 48px 60px; overflow-x:auto; align-items:flex-start; }
  .frame-col{ flex:0 0 auto; width:300px; }
  .frame-label{ font-size:12px; font-weight:600; color:var(--ink); margin-bottom:4px; }
  .frame-sub{ font-size:11px; color:var(--ink-2); margin-bottom:14px; line-height:1.4; min-height:28px; }

  .phone{ width:300px; height:648px; background:var(--card); border-radius:44px; border:9px solid #111214; position:relative; overflow:hidden; box-shadow:0 18px 40px -14px rgba(0,0,0,.28), 0 2px 6px rgba(0,0,0,.08); }
  .statusbar{ height:44px; display:flex; align-items:center; justify-content:space-between; padding:0 22px; font-size:12px; font-weight:600; color:var(--ink); position:relative; z-index:5; background:var(--bg); }
  .island{ position:absolute; top:10px; left:50%; transform:translateX(-50%); width:84px; height:22px; background:#0B0B0C; border-radius:14px; z-index:6; }
  .home-indicator{ position:absolute; bottom:6px; left:50%; transform:translateX(-50%); width:110px; height:4px; border-radius:3px; background:#111; opacity:.8; z-index:9; }
  .screen{ position:absolute; top:44px; left:0; right:0; bottom:0; background:var(--bg); overflow:hidden; }

  /* --- nav bar (normal + edit mode) --- */
  .app-header{ padding:6px 18px 4px; display:flex; align-items:center; justify-content:space-between; background:var(--bg); }
  .app-title{ font-size:20px; font-weight:700; letter-spacing:-.01em; }
  .nav-btn{ font-size:13px; color:var(--teal); font-weight:600; }
  .nav-btn.disabled{ color:var(--ink-2); opacity:.5; }

  .edit-navbar{ padding:8px 18px 4px; display:flex; align-items:center; justify-content:space-between; background:var(--bg); }
  .edit-navbar .center-title{ font-size:13px; font-weight:700; color:var(--ink); }

  .search-row{ display:flex; align-items:center; gap:10px; padding:10px 18px 6px; }
  .search-bar{ flex:1; height:36px; border-radius:10px; background:#EFEDE8; display:flex; align-items:center; gap:6px; padding:0 12px; font-size:13px; color:var(--ink-2); }
  .filter-btn{ position:relative; flex:0 0 auto; width:36px; height:36px; border-radius:10px; background:#EFEDE8; display:flex; align-items:center; justify-content:center; font-size:15px; }
  .filter-btn.active{ background:var(--teal-tint); }
  .filter-badge{ position:absolute; top:-4px; right:-4px; min-width:16px; height:16px; border-radius:8px; background:var(--teal); color:#fff; font-size:9.5px; font-weight:700; display:flex; align-items:center; justify-content:center; padding:0 4px; border:2px solid var(--bg); }

  .list{ padding:2px 14px 20px; display:flex; flex-direction:column; gap:10px; overflow-y:auto; }
  .list.normal{ height:calc(100% - 96px); }
  .list.edit-mode{ height:calc(100% - 160px); }

  /* --- card --- */
  .item-card{ background:var(--card); border-radius:14px; padding:12px 13px; border:1px solid var(--line); position:relative; display:flex; gap:11px; align-items:flex-start; transition:border-color .15s; }
  .item-card.selected{ border-color:var(--teal); background:var(--teal-tint); }
  .select-circle{ width:21px; height:21px; border-radius:50%; border:2px solid #D8D6D0; flex:0 0 auto; margin-top:2px; display:flex; align-items:center; justify-content:center; color:#fff; font-size:11px; font-weight:700; }
  .select-circle.on{ background:var(--teal); border-color:var(--teal); }
  .item-thumb{ flex:0 0 auto; width:52px; height:52px; border-radius:11px; overflow:hidden; background:#EFEDE8; display:flex; align-items:center; justify-content:center; color:var(--ink-2); font-size:18px; }
  .item-content{ flex:1; min-width:0; }
  .item-top{ display:flex; align-items:flex-start; justify-content:space-between; gap:8px; }
  .item-title{ font-size:13px; font-weight:700; line-height:1.35; }
  .dot{ width:7px; height:7px; border-radius:50%; background:var(--teal); flex:0 0 auto; margin-top:5px; }
  .item-meta{ display:flex; align-items:center; gap:8px; margin-top:6px; flex-wrap:wrap; }
  .source-badge{ font-size:10px; color:var(--teal); background:var(--teal-tint); padding:3px 8px; border-radius:6px; font-weight:600; }
  .date-txt{ font-size:10.5px; color:var(--ink-2); }
  .tag-row{ display:flex; gap:6px; margin-top:8px; overflow-x:auto; }
  .tag-pill{ font-size:10px; color:var(--ink-2); background:#F1F0EC; padding:4px 9px; border-radius:100px; white-space:nowrap; }
  .item-card.selected .source-badge{ background:#fff; }
  .item-card.selected .tag-pill{ background:#fff; }

  .item-card.read .item-title{ color:var(--ink-2); font-weight:600; }
  .item-card.read .source-badge{ background:#EDEBE6; color:var(--ink-2); }
  .item-card.read .tag-pill{ opacity:.65; }
  .item-card.read .item-thumb{ opacity:.55; filter:grayscale(.3); }
  .item-card.read .date-txt{ opacity:.75; }

  .state-tag{ position:absolute; top:-9px; left:44px; font-size:9px; font-weight:700; letter-spacing:.02em; background:#1C1C1E; color:#fff; padding:3px 7px; border-radius:6px; text-transform:uppercase; }

  /* --- bottom toolbar --- */
  .bottom-toolbar{ position:absolute; left:0; right:0; bottom:0; height:78px; background:var(--card); border-top:1px solid var(--line); display:flex; align-items:flex-start; justify-content:space-around; padding-top:12px; z-index:8; }
  .toolbar-btn{ display:flex; flex-direction:column; align-items:center; gap:4px; font-size:10.5px; color:var(--ink); font-weight:600; }
  .toolbar-btn .icon{ font-size:17px; }
  .toolbar-btn.disabled{ color:#C7C5C0; opacity:.7; }
  .toolbar-btn.destructive{ color:var(--red); }
  .toolbar-btn.disabled.destructive{ color:#C7C5C0; }

  /* --- alert --- */
  .alert-shade{ position:absolute; inset:0; background:rgba(20,20,20,.35); display:flex; align-items:center; justify-content:center; z-index:20; }
  .alert-box{ width:230px; background:#F6F5F1; border-radius:16px; padding:18px 16px; text-align:center; box-shadow:0 10px 30px rgba(0,0,0,.2); }
  .alert-title{ font-size:14px; font-weight:700; margin-bottom:6px; }
  .alert-sub{ font-size:11.5px; color:var(--ink-2); line-height:1.4; margin-bottom:14px; }
  .alert-btns{ display:flex; flex-direction:column; gap:8px; }
  .alert-btn{ height:36px; border-radius:9px; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:600; }
  .alert-btn.cancel{ background:#EAE8E3; color:var(--ink); }
  .alert-btn.delete{ background:var(--red); color:#fff; }
</style>
</head>
<body>

  <div class="board-header">
    <h1>AggregatorBuddy — Wireframes v3</h1>
    <p>New file, v1 and v2 untouched. Adds multi-select / batch editing to the Home Feed: Edit / Done / Select All in the nav bar, a checkmark indicator per card, a bottom toolbar for batch actions, and a count-aware delete confirmation.</p>
    <span class="tag">Multi-select addition only</span>
  </div>

  <div class="section-label">Home Feed — three states</div>
  <div class="section-sub">Normal browsing → Edit mode with partial selection → batch delete confirmation showing the selected count.</div>

  <div class="board">

    <!-- 1. NORMAL, WITH EDIT ENTRY POINT -->
    <div class="frame-col">
      <div class="frame-label">1 · Home Feed — Normal</div>
      <div class="frame-sub">"Edit" appears in the nav bar next to the title. Tap, long-press, and swipe all work as before.</div>
      <div class="phone">
        <div class="island"></div>
        <div class="statusbar"><span>9:41</span><span>􀛨 􀙇</span></div>
        <div class="screen">
          <div class="app-header">
            <div class="app-title">Saved</div>
            <div class="nav-btn">Edit</div>
          </div>
          <div class="search-row">
            <div class="search-bar">🔍  Search title, source, notes</div>
            <div class="filter-btn active">⚙<span class="filter-badge">2</span></div>
          </div>
          <div class="list normal">
            <div class="item-card">
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Why local-first apps are having a moment</div><div class="dot"></div></div>
                <div class="item-meta"><span class="source-badge">Article</span><span class="date-txt">Sep 20, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">must-read</span></div>
              </div>
            </div>
            <div class="item-card">
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">SwiftData in practice — full walkthrough</div><div class="dot"></div></div>
                <div class="item-meta"><span class="source-badge">YouTube</span><span class="date-txt">Sep 19, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">tutorial</span></div>
              </div>
            </div>
            <div class="item-card">
              <div class="item-thumb">🔗</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">A short note on rest</div><div class="dot"></div></div>
                <div class="item-meta"><span class="source-badge">LinkedIn</span><span class="date-txt">Sep 17, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">spiritual</span></div>
              </div>
            </div>
            <div class="item-card read">
              <div class="item-thumb">📷</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Instagram reel — sourdough starter tips</div></div>
                <div class="item-meta"><span class="source-badge">Instagram</span><span class="date-txt">Sep 15, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">cooking</span></div>
              </div>
            </div>
          </div>
        </div>
        <div class="home-indicator"></div>
      </div>
    </div>

    <!-- 2. EDIT MODE, PARTIAL SELECTION -->
    <div class="frame-col">
      <div class="frame-label">2 · Home Feed — Edit Mode</div>
      <div class="frame-sub">"Select All" left, "Done" right, live count in center. Tapping a card toggles its checkmark. Toolbar enables once ≥1 item is selected.</div>
      <div class="phone">
        <div class="island"></div>
        <div class="statusbar"><span>9:41</span><span>􀛨 􀙇</span></div>
        <div class="screen">
          <div class="edit-navbar">
            <div class="nav-btn">Select All</div>
            <div class="center-title">2 Selected</div>
            <div class="nav-btn">Done</div>
          </div>
          <div class="list edit-mode" style="margin-top:6px;">
            <div class="item-card selected">
              <div class="select-circle on">✓</div>
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Why local-first apps are having a moment</div></div>
                <div class="item-meta"><span class="source-badge">Article</span><span class="date-txt">Sep 20, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">must-read</span></div>
              </div>
            </div>
            <div class="item-card">
              <div class="select-circle"></div>
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">SwiftData in practice — full walkthrough</div></div>
                <div class="item-meta"><span class="source-badge">YouTube</span><span class="date-txt">Sep 19, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">tutorial</span></div>
              </div>
            </div>
            <div class="item-card selected">
              <div class="select-circle on">✓</div>
              <div class="item-thumb">🔗</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">A short note on rest</div></div>
                <div class="item-meta"><span class="source-badge">LinkedIn</span><span class="date-txt">Sep 17, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">spiritual</span></div>
              </div>
            </div>
            <div class="item-card read">
              <div class="select-circle"></div>
              <div class="item-thumb">📷</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Instagram reel — sourdough starter tips</div></div>
                <div class="item-meta"><span class="source-badge">Instagram</span><span class="date-txt">Sep 15, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">cooking</span></div>
              </div>
            </div>
          </div>
          <div class="bottom-toolbar">
            <div class="toolbar-btn destructive"><span class="icon">🗑</span>Delete</div>
            <div class="toolbar-btn"><span class="icon">●</span>Mark Read</div>
            <div class="toolbar-btn"><span class="icon">○</span>Mark Unread</div>
          </div>
        </div>
        <div class="home-indicator"></div>
      </div>
    </div>

    <!-- 3. EDIT MODE — NOTHING SELECTED (toolbar disabled) -->
    <div class="frame-col">
      <div class="frame-label">3 · Edit Mode — Nothing Selected</div>
      <div class="frame-sub">Entry state right after tapping "Edit": all circles empty, toolbar buttons disabled/greyed until something is picked.</div>
      <div class="phone">
        <div class="island"></div>
        <div class="statusbar"><span>9:41</span><span>􀛨 􀙇</span></div>
        <div class="screen">
          <div class="edit-navbar">
            <div class="nav-btn">Select All</div>
            <div class="center-title">Select Items</div>
            <div class="nav-btn">Done</div>
          </div>
          <div class="list edit-mode" style="margin-top:6px;">
            <div class="item-card">
              <div class="select-circle"></div>
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Why local-first apps are having a moment</div></div>
                <div class="item-meta"><span class="source-badge">Article</span><span class="date-txt">Sep 20, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">must-read</span></div>
              </div>
            </div>
            <div class="item-card">
              <div class="select-circle"></div>
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">SwiftData in practice — full walkthrough</div></div>
                <div class="item-meta"><span class="source-badge">YouTube</span><span class="date-txt">Sep 19, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">tech</span><span class="tag-pill">tutorial</span></div>
              </div>
            </div>
            <div class="item-card">
              <div class="select-circle"></div>
              <div class="item-thumb">🔗</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">A short note on rest</div></div>
                <div class="item-meta"><span class="source-badge">LinkedIn</span><span class="date-txt">Sep 17, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">spiritual</span></div>
              </div>
            </div>
            <div class="item-card read">
              <div class="select-circle"></div>
              <div class="item-thumb">📷</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Instagram reel — sourdough starter tips</div></div>
                <div class="item-meta"><span class="source-badge">Instagram</span><span class="date-txt">Sep 15, 2026</span></div>
                <div class="tag-row"><span class="tag-pill">cooking</span></div>
              </div>
            </div>
          </div>
          <div class="bottom-toolbar">
            <div class="toolbar-btn disabled destructive"><span class="icon">🗑</span>Delete</div>
            <div class="toolbar-btn disabled"><span class="icon">●</span>Mark Read</div>
            <div class="toolbar-btn disabled"><span class="icon">○</span>Mark Unread</div>
          </div>
        </div>
        <div class="home-indicator"></div>
      </div>
    </div>

    <!-- 4. BATCH DELETE CONFIRMATION -->
    <div class="frame-col">
      <div class="frame-label">4 · Batch Delete Confirmation</div>
      <div class="frame-sub">Same alert pattern as single delete, count-aware copy: "Delete 3 items?"</div>
      <div class="phone">
        <div class="island"></div>
        <div class="statusbar"><span>9:41</span><span>􀛨 􀙇</span></div>
        <div class="screen">
          <div class="edit-navbar" style="opacity:.35">
            <div class="nav-btn">Select All</div>
            <div class="center-title">3 Selected</div>
            <div class="nav-btn">Done</div>
          </div>
          <div class="list edit-mode" style="margin-top:6px; opacity:.35;">
            <div class="item-card selected">
              <div class="select-circle on">✓</div>
              <div class="item-thumb" style="background:linear-gradient(135deg,#2F6F5E,#4a8c78);color:#fff;">▶</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">Why local-first apps are having a moment</div></div>
                <div class="item-meta"><span class="source-badge">Article</span><span class="date-txt">Sep 20, 2026</span></div>
              </div>
            </div>
            <div class="item-card selected">
              <div class="select-circle on">✓</div>
              <div class="item-thumb">🔗</div>
              <div class="item-content">
                <div class="item-top"><div class="item-title">A short note on rest</div></div>
                <div class="item-meta"><span class="source-badge">LinkedIn</span><span class="date-txt">Sep 17, 2026</span></div>
              </div>
            </div>
          </div>
          <div class="bottom-toolbar" style="opacity:.35;">
            <div class="toolbar-btn destructive"><span class="icon">🗑</span>Delete</div>
            <div class="toolbar-btn"><span class="icon">●</span>Mark Read</div>
            <div class="toolbar-btn"><span class="icon">○</span>Mark Unread</div>
          </div>
          <div class="alert-shade">
            <div class="alert-box">
              <div class="alert-title">Delete 3 items?</div>
              <div class="alert-sub">This cannot be undone. All 3 selected links and their notes will be permanently removed.</div>
              <div class="alert-btns">
                <div class="alert-btn delete">Delete</div>
                <div class="alert-btn cancel">Cancel</div>
              </div>
            </div>
          </div>
        </div>
        <div class="home-indicator"></div>
      </div>
    </div>

  </div>

</body>
</html>