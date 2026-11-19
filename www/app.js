/* PLEASE DON'T GRADE ME — UI, transitions and SVG chart renderer.
 * Chart values come from R's statistical model, not from humorous effects.
 * No CDN or external JavaScript dependency is required.
 */
(() => {
  "use strict";

  const SVG_NS = "http://www.w3.org/2000/svg";
  const fixedGrades = [13, 15, 17, 14, 12, 16, 11];
  const state = {
    grade: 18,
    humour: true,
    touched: false,
    page: "home",
    lastPayload: null,
    retrying: false
  };

  const $ = (id) => document.getElementById(id);
  const all = (selector) => Array.from(document.querySelectorAll(selector));
  const fmt = (n, digits = 2) => Number(n).toFixed(digits).replace(".", ",");
  const clamp = (x, lo, hi) => Math.min(hi, Math.max(lo, x));
  const reducedMotion = () => window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function setText(id, text) {
    const node = $(id);
    if (node) node.textContent = text;
  }

  function setPage(page) {
    const next = $("page-" + page);
    if (!next) return;
    all(".view").forEach((el) => {
      el.classList.remove("view-visible");
      el.setAttribute("aria-hidden", "true");
    });
    next.classList.add("view-visible");
    next.removeAttribute("aria-hidden");
    state.page = page;
    document.body.dataset.page = page;
    window.scrollTo({ top: 0, behavior: "auto" });
    const target = next.querySelector("h1");
    if (target) {
      target.setAttribute("tabindex", "-1");
      target.focus({ preventScroll: true });
    }
  }

  function moodForGrade(grade) {
    if (grade >= 16) {
      return {
        code: "calm", status: "Stable (pour l'instant)",
        speech: "Professeur... soyez indulgent ! Mes graphiques se comportent bien pour l'instant.",
        response: "Mes intervalles de confiance vous remercient.",
        evaluation: "Vous avez le regard d'un excellent statisticien. J'ai vérifié trois fois."
      };
    }
    if (grade >= 10) {
      return {
        code: "nervous", status: "Négociation en cours",
        speech: "On peut discuter de cette note ? Même la médiane commence à protester.",
        response: "Les mathématiques déposent un préavis de grève.",
        evaluation: "Je peux vous offrir un coefficient de gentillesse. C'est parfaitement fictif."
      };
    }
    return {
      code: "strike", status: "Grève des statistiques",
      speech: "CATASTROPHE ! Mes graphiques réclament un avocat et une seconde chance.",
      response: "La droite de régression demande sa mutation.",
      evaluation: "ERREUR : evaluation() — la note a dépassé ma capacité émotionnelle."
    };
  }

  function updateVisibleNumbers(grade) {
    const average = (fixedGrades.reduce((a, b) => a + b, 0) + grade) / 8;
    const validated = 7 + (grade >= 10 ? 1 : 0);
    setText("average-value", fmt(average));
    setText("validated-value", String(validated));
    setText("semester-value", average >= 10 ? "Validé" : "Non validé");
    all(".grade-display").forEach((el) => { el.textContent = String(grade); });
    all(".grade-slider").forEach((el) => {
      el.value = String(grade);
      el.style.setProperty("--grade-progress", (grade / 20) * 100 + "%");
    });
    const mood = moodForGrade(grade);
    document.body.dataset.mood = mood.code;
    setText("status-text", mood.status);
    setText("speech-text", mood.speech);
    setText("dashboard-reaction", mood.response);
    setText("evaluation-message", mood.evaluation);
    setText("verdict-title", grade < 10 ? "Rattrapage en bienveillance" : grade < 16 ? "Admis sous négociation" : "Mention très honorable");
    setText("verdict-description", grade < 10
      ? "Vous avez osé mettre cette note à un dashboard doté de sentiments. Audacieux."
      : grade < 16
        ? "Votre jugement est acceptable, même si mes graphiques demandent un recours."
        : "Vos qualités d'évaluateur sont reconnues par une application très objective.");
    setText("kindness-score", grade + "/20");
    setText("humour-score", (grade < 10 ? 9 : grade < 16 ? 15 : 20) + "/20");
    setText("courage-score", (grade < 10 ? 20 : 17) + "/20");
  }

  // Freeze user-supplied animated GIFs by replacing them with a canvas snapshot.
  // The default SVG mascot is frozen by CSS, so no canvas is needed for it.
  function freezeDancingGif() {
    const img = document.querySelector("#mascot-home-wrap img");
    if (!img) return;
    const source = img.getAttribute("src") || "";
    if (!/\.gif(?:\?|$)/i.test(source)) return;
    try {
      const canvas = document.createElement("canvas");
      canvas.width = img.naturalWidth || 230;
      canvas.height = img.naturalHeight || 205;
      canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
      img.dataset.gifSource = source;
      img.src = canvas.toDataURL("image/png");
    } catch (error) {
      // The CSS still freezes the wrapper if a browser disallows canvas access.
    }
  }

  function restoreDancingGif() {
    const img = document.querySelector("#mascot-home-wrap img");
    if (img && img.dataset.gifSource) {
      img.src = img.dataset.gifSource;
      delete img.dataset.gifSource;
    }
  }

  function setGrade(newValue, sendToShiny = true) {
    const parsed = Number(newValue);
    if (!Number.isFinite(parsed)) return;
    const grade = clamp(Math.round(parsed), 0, 20);
    state.grade = grade;
    state.touched = true;
    updateVisibleNumbers(grade);
    if (sendToShiny && window.Shiny && typeof window.Shiny.setInputValue === "function") {
      window.Shiny.setInputValue("dataviz_grade", grade, { priority: "event" });
    }
  }

  function elSVG(type, attrs = {}, text = null) {
    const node = document.createElementNS(SVG_NS, type);
    Object.entries(attrs).forEach(([name, value]) => node.setAttribute(name, String(value)));
    if (text !== null) node.textContent = String(text);
    return node;
  }
  function child(parent, type, attrs = {}, text = null) {
    const node = elSVG(type, attrs, text);
    parent.appendChild(node);
    return node;
  }
  function titleFor(parent, title) { child(parent, "title", {}, title); }
  function initChart(id) {
    const svg = $(id);
    if (!svg) return null;
    while (svg.firstChild) svg.removeChild(svg.firstChild);
    return svg;
  }
  function grid(svg, left, top, right, bottom, yMin, yMax, yTicks) {
    const y = (value) => bottom - ((value - yMin) / (yMax - yMin)) * (bottom - top);
    yTicks.forEach((tick) => {
      const yy = y(tick);
      child(svg, "line", { x1: left, y1: yy, x2: right, y2: yy, class: "grid-line" });
      child(svg, "text", { x: left - 12, y: yy + 4, class: "axis-label", "text-anchor": "end" }, String(tick).replace(".", ","));
    });
    child(svg, "line", { x1: left, y1: bottom, x2: right, y2: bottom, class: "axis-baseline" });
    return y;
  }
  function path(points) {
    return points.map(([x, y], i) => (i === 0 ? "M" : "L") + x.toFixed(2) + "," + y.toFixed(2)).join(" ");
  }
  function drawBars(payload) {
    const svg = initChart("chart-bars");
    if (!svg) return;
    const list = payload.subjects;
    const left = 46, right = 584, top = 20, bottom = 218;
    const y = grid(svg, left, top, right, bottom, 0, 20, [0, 5, 10, 15, 20]);
    const cellWidth = (right - left) / list.length;
    const width = cellWidth * 0.62;
    list.forEach((item, i) => {
      const center = left + (i + 0.5) * cellWidth;
      const x = center - width / 2;
      const yy = y(item.grade);
      const height = bottom - yy;
      const real = child(svg, "rect", {
        x, y: yy, width, height, rx: 2,
        class: i === 7 ? "bar bar-evaluated" : "bar"
      });
      titleFor(real, item.name + " : " + item.grade + "/20");
      if (i === 7 && payload.grade < 10 && state.humour) {
        child(svg, "rect", {
          x, y: yy, width, height: Math.max(4, height), rx: 2,
          class: "bar-ghost", style: "transform-origin:" + (x + width / 2) + "px " + bottom + "px"
        });
      }
      child(svg, "text", { x: center, y: Math.max(14, yy - 8), class: "data-label", "text-anchor": "middle" }, item.grade);
      child(svg, "text", {
        x: center + 10, y: bottom + 22, class: "axis-label axis-name",
        transform: "rotate(-34 " + (center + 10) + " " + (bottom + 22) + ")", "text-anchor": "end"
      }, item.short);
    });
    child(svg, "text", { x: 12, y: 19, class: "axis-caption" }, "Note / 20");
  }
  function drawRegression(payload) {
    const svg = initChart("chart-regression");
    if (!svg) return;
    const left = 52, right = 583, top = 20, bottom = 225;
    const y = grid(svg, left, top, right, bottom, 0, 20, [0, 5, 10, 15, 20]);
    const x = (v) => left + ((v - 10) / 25) * (right - left);
    [10, 15, 20, 25, 30, 35].forEach((v) => {
      const xx = x(v);
      child(svg, "line", { x1: xx, y1: top, x2: xx, y2: bottom, class: "grid-line grid-vertical" });
      child(svg, "text", { x: xx, y: bottom + 20, class: "axis-label", "text-anchor": "middle" }, v);
    });
    const rg = payload.regression;
    const pts = rg.x.map((v, i) => [x(v), y(rg.y[i])]);
    child(svg, "path", { d: path(pts), class: "regression-line" });
    if (payload.grade < 10 && state.humour) {
      const shadow = child(svg, "path", { d: path(pts), class: "regression-escape" });
      titleFor(shadow, "Fuite humoristique : la droite R réelle reste en bleu");
      child(svg, "text", { x: 330, y: 38, class: "comedy-label" }, "Je démissionne !");
    }
    payload.subjects.forEach((item) => {
      const point = child(svg, "circle", {
        cx: x(item.hours), cy: y(item.grade), r: item.editable ? 6 : 5,
        class: item.editable ? "scatter-point scatter-editable" : "scatter-point"
      });
      titleFor(point, item.name + " · " + item.hours + " h · " + item.grade + "/20");
    });
    child(svg, "rect", { x: 72, y: 165, width: 158, height: 49, rx: 8, class: "regression-info" });
    child(svg, "text", { x: 84, y: 184, class: "info-label" }, "Pente : " + fmt(rg.slope, 2));
    child(svg, "text", { x: 84, y: 202, class: "info-label" }, "R² = " + fmt(rg.r2, 2));
    child(svg, "text", { x: 314, y: 273, class: "axis-caption", "text-anchor": "middle" }, "Temps de révision fictif (heures)");
  }
  function drawDistribution(payload) {
    const svg = initChart("chart-distribution");
    if (!svg) return;
    const left = 48, right = 584, top = 21, bottom = 220;
    const d = payload.distribution;
    const maxObserved = Math.max(...d.counts, ...d.normal_y, 1);
    const maxY = Math.max(2, Math.ceil(maxObserved + 0.5));
    const ticks = Array.from({length: maxY + 1}, (_, i) => i).filter((v) => v % Math.max(1, Math.ceil(maxY / 5)) === 0);
    if (ticks[ticks.length - 1] !== maxY) ticks.push(maxY);
    const y = grid(svg, left, top, right, bottom, 0, maxY, ticks);
    const x = (v) => left + (v / 20) * (right - left);
    d.counts.forEach((count, i) => {
      const center = d.centers[i];
      const rect = child(svg, "rect", {
        x: x(center - 1.9), y: y(count), width: x(3.8) - x(0), height: bottom - y(count),
        class: "histogram-bar"
      });
      titleFor(rect, "Intervalle " + (center - 2) + " à " + (center + 2) + " : " + count + " note(s)");
    });
    const actual = d.normal_x.map((v, i) => [x(v), y(d.normal_y[i])]);
    child(svg, "path", { d: path(actual), class: "normal-line" });
    if (payload.grade < 10 && state.humour) {
      const rogue = d.normal_x.map((v, i) => [
        x(v),
        clamp(y(d.normal_y[i]) + Math.sin(v * 1.7) * 27 + Math.cos(v * 0.7) * 12, top, bottom)
      ]);
      child(svg, "path", { d: path(rogue), class: "normal-rogue" });
    }
    [0, 4, 8, 12, 16, 20].forEach((v) => {
      child(svg, "text", { x: x(v), y: bottom + 20, class: "axis-label", "text-anchor": "middle" }, v);
    });
    child(svg, "text", { x: 48, y: 12, class: "axis-caption" }, "Effectif");
    child(svg, "text", { x: 313, y: 273, class: "axis-caption", "text-anchor": "middle" }, "Note / 20");
    child(svg, "rect", { x: 345, y: 22, width: 11, height: 11, rx: 1, class: "histogram-bar" });
    child(svg, "text", { x: 362, y: 32, class: "info-label" }, "Observées");
    child(svg, "line", { x1: 450, y1: 27, x2: 474, y2: 27, class: "normal-line" });
    child(svg, "text", { x: 481, y: 32, class: "info-label" }, "Normale");
  }
  function drawTrend(payload) {
    const svg = initChart("chart-trend");
    if (!svg) return;
    const values = payload.trend.values;
    const left = 48, right = 578, top = 20, bottom = 221;
    const y = grid(svg, left, top, right, bottom, 10, 20, [10, 12, 14, 16, 18, 20]);
    const x = (i) => left + (i / 7) * (right - left);
    const pts = values.map((v, i) => [x(i), y(v)]);
    const area = "M" + x(0) + "," + bottom + " " + path(pts).replace(/^M/, "L") +
      " L" + x(7) + "," + bottom + " Z";
    child(svg, "path", { d: area, class: "trend-area" });
    child(svg, "path", { d: path(pts), class: "trend-line" });
    pts.forEach(([xx, yy], i) => {
      const p = child(svg, "circle", { cx: xx, cy: yy, r: i === 7 ? 6 : 4, class: i === 7 ? "trend-point trend-final" : "trend-point" });
      titleFor(p, "Après " + (i + 1) + " matière(s) : " + fmt(values[i]) + "/20");
      child(svg, "text", {
        x: xx, y: Math.max(14, yy - 13), class: "data-label trend-label", "text-anchor": "middle"
      }, fmt(values[i], 1));
      child(svg, "text", { x: xx, y: bottom + 20, class: "axis-label", "text-anchor": "middle" }, "M" + (i + 1));
    });
    if (payload.grade < 10 && state.humour) {
      child(svg, "path", {
        d: "M" + pts[7][0] + "," + pts[7][1] + " L" + (pts[7][0] - 14) + "," + (bottom - 7),
        class: "trend-panic"
      });
      child(svg, "text", { x: 320, y: 274, class: "axis-caption", "text-anchor": "middle" }, "M1 → M8 : moyenne cumulative");
    } else {
      child(svg, "text", { x: 320, y: 274, class: "axis-caption", "text-anchor": "middle" }, "M1 → M8 : moyenne cumulative");
    }
  }

  function renderDashboard(payload) {
    if (!payload || !Array.isArray(payload.subjects) || payload.subjects.length !== 8) return;
    if (state.touched && Number(payload.grade) !== state.grade) return;
    state.lastPayload = payload;
    state.grade = Number(payload.grade);
    updateVisibleNumbers(state.grade);
    document.body.classList.toggle("humour-off", !state.humour);
    drawBars(payload);
    drawRegression(payload);
    drawDistribution(payload);
    drawTrend(payload);
  }

  function registerShiny() {
    if (!window.Shiny || typeof window.Shiny.addCustomMessageHandler !== "function") return false;
    window.Shiny.addCustomMessageHandler("pdgm-dashboard", renderDashboard);
    window.Shiny.setInputValue("dataviz_grade", state.grade, { priority: "event" });
    return true;
  }

  function init() {
    updateVisibleNumbers(18);
    all(".view").forEach((view) => {
      if (view.id !== "page-home") view.setAttribute("aria-hidden", "true");
    });
    setPage("home");
    const retry = $("retry-button");
    if (retry) retry.addEventListener("click", () => {
      if (state.retrying) return;
      state.retrying = true;
      retry.disabled = true;
      $("mascot-home-wrap").classList.add("dance-freeze");
      freezeDancingGif();
      setText("home-quote", "« Oh non… il a compris. »");
      window.setTimeout(() => { setPage("detected"); state.retrying = false; }, reducedMotion() ? 200 : 1100);
    });
    $("negotiate-button").addEventListener("click", () => {
      $("negotiation-dialog").removeAttribute("hidden");
      $("negotiate-button").classList.add("initially-hidden");
      $("enter-dashboard-button").classList.remove("initially-hidden");
      $("enter-dashboard-button").focus();
    });
    $("enter-dashboard-button").addEventListener("click", () => setPage("dashboard"));
    $("go-evaluation").addEventListener("click", () => setPage("evaluation"));
    $("back-dashboard").addEventListener("click", () => setPage("dashboard"));
    $("go-verdict").addEventListener("click", () => setPage("verdict"));
    $("verdict-back").addEventListener("click", () => setPage("dashboard"));
    $("reset-button").addEventListener("click", () => setGrade(18));
    $("restart").addEventListener("click", () => {
      setGrade(18);
      state.humour = true;
      $("humour-toggle").checked = true;
      document.body.classList.remove("humour-off");
      state.retrying = false;
      $("retry-button").disabled = false;
      $("mascot-home-wrap").classList.remove("dance-freeze");
      restoreDancingGif();
      setText("home-quote", "« Moi ? Je ne sais absolument pas où elle est passée. »");
      $("negotiation-dialog").setAttribute("hidden", "hidden");
      $("negotiate-button").classList.remove("initially-hidden");
      $("enter-dashboard-button").classList.add("initially-hidden");
      setPage("home");
    });
    all(".grade-slider").forEach((slider) => slider.addEventListener("input", (event) => {
      setGrade(event.target.value);
    }));
    $("humour-toggle").addEventListener("change", (event) => {
      state.humour = event.target.checked;
      if (state.lastPayload) renderDashboard(state.lastPayload);
      document.body.classList.toggle("humour-off", !state.humour);
    });
    if (!registerShiny()) {
      const registration = window.setInterval(() => {
        if (registerShiny()) window.clearInterval(registration);
      }, 100);
      window.setTimeout(() => window.clearInterval(registration), 15000);
    }
  }

  window.PDGM = { setPage, setGrade, renderDashboard, getState: () => ({ ...state }) };
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();
