/**
 * BEL Central Library — Radar Sweep & PCB Circuit → BEL Logo Engine
 * -----------------------------------------------------------------------
 * Pure HTML5 Canvas 2D API.  Zero external dependencies.
 * Works offline / intranet — no CDN, no npm, no WebGL.
 *
 * Phase timeline (total ≈ 8.3 s, then auto-replays):
 *  RADAR          0 – 1.6 s   Radar sweep + phosphor trail
 *  TRACING        1.6 – 3.6 s PCB traces & solder nodes draw in
 *  CHARGING       3.6 – 5.0 s Data-pulse travels highways → convergence arc
 *  EMBLEM_FORMED  5.0 – 6.4 s BEL emblem materialises with shockwave
 *  ELABORATING    6.4 – 8.3 s Full logo wipe-reveal from left
 *  COMPLETED      8.3 s +     Ambient sheen loop, auto-replay after 6 s
 */
(function () {
    'use strict';

    const Engine = {
        // public state
        canvas: null,
        ctx: null,
        animFrameId: null,
        dpr: 1,
        width: 500,
        height: 380,
        counterEl: null,
        statusEl: null,
        imgEmblem: null,
        imgFull: null,
        imagesReady: false,

        // phase machine
        phase: 'RADAR',
        phaseStartTime: 0,

        // radar
        radarAngle: -Math.PI / 2,
        radarTrail: [],
        rangePulseR: 0,
        rangePulseAlpha: 0,

        // circuit traces
        traces: [],
        minorTraces: [],
        nodes: [],
        traceProgress: 0,

        // charging
        pulses: [],
        chargeParticles: [],
        arcAlpha: 0,

        // shockwave
        shockwaveRadius: 0,
        shockwaveAlpha: 0,

        // emblem breathing
        breathPhase: 0,

        // compat shims
        books: [],
        particles: [],

        // ----------------------------------------------------------------
        // PUBLIC API
        // ----------------------------------------------------------------
        init() {
            this.canvas = document.getElementById('fallingBooksCanvas');
            if (!this.canvas) return;
            this.ctx = this.canvas.getContext('2d');
            this.counterEl = document.getElementById('fallingBooksCount');
            this.statusEl  = document.getElementById('fallingBooksStatus');

            this._polyfillRoundRect();
            this._loadImages();
            this._resize();
            window.addEventListener('resize', () => this._resize());

            // Click to replay
            const stage = this.canvas.closest('.falling-books-stage,.bel-logo-stage') || this.canvas;
            stage.addEventListener('click', () => this.resetAndPlay());

            // Legacy buttons
            const dropBtn  = document.getElementById('btnDropBook');
            if (dropBtn)  dropBtn.addEventListener('click',  function(e){ e.stopPropagation(); });
            const resetBtn = document.getElementById('btnResetStack');
            if (resetBtn) resetBtn.addEventListener('click', (e) => { e.stopPropagation(); this.resetAndPlay(); });

            this.resetAndPlay();
            if (!this.animFrameId) this._loop();
        },

        resetAndPlay() {
            this.phase          = 'RADAR';
            this.phaseStartTime = performance.now();
            this.radarAngle     = -Math.PI / 2;
            this.radarTrail     = [];
            this.rangePulseR    = 0;
            this.rangePulseAlpha = 0;
            this.traceProgress  = 0;
            this.pulses         = [];
            this.chargeParticles = [];
            this.arcAlpha       = 0;
            this.shockwaveRadius = 0;
            this.shockwaveAlpha  = 0;
            this.breathPhase    = 0;
            this._buildTraces();
            this._status('Radar Scanning...', 'Initialising');
        },

        dropExtraBook() { /* no-op shim */ },

        // ----------------------------------------------------------------
        // INTERNALS
        // ----------------------------------------------------------------
        _polyfillRoundRect() {
            if (!this.ctx.roundRect) {
                this.ctx.roundRect = function (x, y, w, h, r) {
                    if (w < 2 * r) r = w / 2;
                    if (h < 2 * r) r = h / 2;
                    this.beginPath();
                    this.moveTo(x + r, y);
                    this.arcTo(x + w, y, x + w, y + h, r);
                    this.arcTo(x + w, y + h, x, y + h, r);
                    this.arcTo(x, y + h, x, y, r);
                    this.arcTo(x, y, x + w, y, r);
                    this.closePath();
                    return this;
                };
            }
        },

        _loadImages() {
            var self = this;
            var n = 0;
            function done() { if (++n >= 2) self.imagesReady = true; }
            var base = (window.BEL_ASSETS && window.BEL_ASSETS.emblem)
                ? window.BEL_ASSETS.emblem : 'image.asp?file=emblem&v=4';
            var full = (window.BEL_ASSETS && window.BEL_ASSETS.fullLogo)
                ? window.BEL_ASSETS.fullLogo : 'image.asp?file=full&v=4';

            this.imgEmblem = new Image();
            this.imgEmblem.onload = done;
            this.imgEmblem.src = base;

            this.imgFull = new Image();
            this.imgFull.onload = done;
            this.imgFull.src = full;

            if (this.imgEmblem.complete && this.imgFull.complete) this.imagesReady = true;
        },

        _resize() {
            if (!this.canvas) return;
            var rect  = this.canvas.getBoundingClientRect();
            this.width  = rect.width  || 500;
            this.height = rect.height || 380;
            this.dpr    = Math.min(window.devicePixelRatio || 1, 2);
            this.canvas.width  = this.width  * this.dpr;
            this.canvas.height = this.height * this.dpr;
            this.ctx.scale(this.dpr, this.dpr);
            this._buildTraces();
        },

        _status(s, c) {
            if (this.statusEl  && s) this.statusEl.textContent  = s;
            if (this.counterEl && c) this.counterEl.textContent = c;
        },

        _buildTraces() {
            var W = this.width, H = this.height;
            var cx = W / 2, cy = H / 2;

            this.traces = [
                [
                    { x: cx - 175, y: 30 },
                    { x: cx - 175, y: cy - 85 },
                    { x: cx - 80,  y: cy - 85 },
                    { x: cx - 80,  y: cy - 30 },
                    { x: cx,       y: cy - 30 }
                ],
                [
                    { x: cx + 180, y: 30 },
                    { x: cx + 180, y: cy - 52 },
                    { x: cx + 85,  y: cy - 52 },
                    { x: cx + 85,  y: cy },
                    { x: cx,       y: cy }
                ],
                [
                    { x: cx - 155, y: H - 30 },
                    { x: cx - 155, y: cy + 72 },
                    { x: cx - 42,  y: cy + 72 },
                    { x: cx - 42,  y: cy + 30 },
                    { x: cx,       y: cy + 30 }
                ]
            ];

            this.minorTraces = [
                [{ x: cx - 175, y: cy }, { x: cx - 125, y: cy }, { x: cx - 125, y: cy - 85 }],
                [{ x: cx + 180, y: cy + 40 }, { x: cx + 130, y: cy + 40 }, { x: cx + 130, y: cy - 52 }],
                [{ x: cx - 155, y: cy - 55 }, { x: cx - 100, y: cy - 55 }, { x: cx - 100, y: cy - 85 }],
                [{ x: cx - 42,  y: cy - 52 }, { x: cx + 42,  y: cy - 52 }, { x: cx + 42,  y: cy - 85 }]
            ];

            this.nodes = [];
            var allSegs = this.traces.concat(this.minorTraces);
            for (var s = 0; s < allSegs.length; s++) {
                var seg = allSegs[s];
                for (var p = 0; p < seg.length; p++) {
                    this.nodes.push({ x: seg[p].x, y: seg[p].y, r: 3.2 });
                }
            }
            var extras = [
                { x: cx - 175, y: cy }, { x: cx + 180, y: cy + 40 },
                { x: cx - 100, y: cy - 115 }, { x: cx + 82, y: cy + 78 },
                { x: cx, y: cy + 72 }, { x: cx - 155, y: cy - 55 },
                { x: cx + 42, y: cy - 85 }, { x: cx - 42, y: cy - 52 }
            ];
            for (var e = 0; e < extras.length; e++) {
                this.nodes.push({ x: extras[e].x, y: extras[e].y, r: 2.2 });
            }
        },

        _loop() {
            this._update();
            this._render();
            this.animFrameId = requestAnimationFrame(this._loop.bind(this));
        },

        _update() {
            var now     = performance.now();
            var elapsed = now - this.phaseStartTime;
            var dt      = 16.67;

            if (this.phase === 'RADAR') {
                var speed = (Math.PI * 2) / 1600;
                this.radarAngle += speed * dt;
                this.radarTrail.push({ angle: this.radarAngle, alpha: 1.0 });
                for (var i = this.radarTrail.length - 1; i >= 0; i--) {
                    this.radarTrail[i].alpha -= 0.026;
                    if (this.radarTrail[i].alpha <= 0) this.radarTrail.splice(i, 1);
                }
                this.rangePulseR += 2.5;
                var maxR = Math.min(this.width, this.height) * 0.52;
                if (this.rangePulseR > maxR) {
                    this.rangePulseR = 0;
                    this.rangePulseAlpha = 0.65;
                }
                this.rangePulseAlpha = Math.max(0, this.rangePulseAlpha - 0.011);

                if (elapsed >= 1600) {
                    this.phase = 'TRACING';
                    this.phaseStartTime = now;
                    this.traceProgress = 0;
                    this._status('Circuit Assembling...', 'PCB Routing');
                }

            } else if (this.phase === 'TRACING') {
                this.traceProgress = Math.min(1, elapsed / 2000);

                if (Math.random() < 0.5) {
                    var hwy = this.traces[Math.floor(Math.random() * this.traces.length)];
                    var pt  = this._ptAlong(hwy, this.traceProgress);
                    this.chargeParticles.push({
                        x: pt.x, y: pt.y,
                        vx: (Math.random() - 0.5) * 2, vy: (Math.random() - 0.5) * 2,
                        alpha: 0.9, size: 1.5 + Math.random() * 2, color: '#00c8f8'
                    });
                }

                if (elapsed >= 2000) {
                    this.phase = 'CHARGING';
                    this.phaseStartTime = now;
                    this.pulses = [];
                    for (var ti = 0; ti < this.traces.length; ti++) {
                        this.pulses.push({
                            seg: this.traces[ti],
                            t: 0,
                            speed: 0.00085 + ti * 0.00012,
                            color: '#00d4ff',
                            size: 4.5
                        });
                    }
                    this._status('Charging Highways...', 'Data Pulse');
                }

            } else if (this.phase === 'CHARGING') {
                for (var pi = 0; pi < this.pulses.length; pi++) {
                    var pulse = this.pulses[pi];
                    pulse.t = Math.min(1, pulse.t + pulse.speed * dt);
                    if (Math.random() < 0.38) {
                        var ppt = this._ptAlong(pulse.seg, pulse.t);
                        this.chargeParticles.push({
                            x: ppt.x, y: ppt.y,
                            vx: (Math.random() - 0.5) * 1.6, vy: (Math.random() - 0.5) * 1.6,
                            alpha: 1, size: 2 + Math.random() * 2.5, color: '#00e5ff'
                        });
                    }
                }
                if (elapsed >= 1400) {
                    this.arcAlpha       = 1;
                    this.shockwaveRadius = 6;
                    this.shockwaveAlpha  = 1;
                    this.phase = 'EMBLEM_FORMED';
                    this.phaseStartTime = now;
                    this._status('BEL Emblem Formed', 'Convergence');
                }

            } else if (this.phase === 'EMBLEM_FORMED') {
                this.shockwaveRadius += 5.5;
                this.shockwaveAlpha   = Math.max(0, this.shockwaveAlpha - 0.020);
                this.arcAlpha         = Math.max(0, this.arcAlpha - 0.028);
                this.breathPhase     += 0.055;
                if (elapsed >= 1400) {
                    this.phase = 'ELABORATING';
                    this.phaseStartTime = now;
                    this._status('Bharat Electronics Limited', 'Logo Reveal');
                }

            } else if (this.phase === 'ELABORATING') {
                this.breathPhase += 0.038;
                if (elapsed >= 1900) {
                    this.phase = 'COMPLETED';
                    this.phaseStartTime = now;
                    this._status('Bharat Electronics Limited', '');
                }

            } else if (this.phase === 'COMPLETED') {
                this.breathPhase += 0.022;
                if (elapsed >= 6000) this.resetAndPlay();
            }

            for (var ci = this.chargeParticles.length - 1; ci >= 0; ci--) {
                var cp = this.chargeParticles[ci];
                cp.x += cp.vx; cp.y += cp.vy;
                cp.alpha -= 0.038;
                if (cp.alpha <= 0) this.chargeParticles.splice(ci, 1);
            }
        },

        _render() {
            var ctx = this.ctx;
            var W   = this.width, H = this.height;
            var cx  = W / 2, cy = H / 2;
            var now = performance.now();
            var el  = now - this.phaseStartTime;

            ctx.clearRect(0, 0, W, H);
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, W, H);

            if (this.phase === 'RADAR') {
                this._drawRadar(ctx, cx, cy);
            }

            if (this.phase === 'TRACING') {
                this._drawGridGhost(ctx, cx, cy, 0.07);
                this._drawTraces(ctx, this.traceProgress, 1.0);
                this._drawNodes(ctx, 1.0);
            }

            if (this.phase === 'CHARGING') {
                this._drawGridGhost(ctx, cx, cy, 0.045);
                this._drawTraces(ctx, 1.0, 1.0);
                this._drawNodes(ctx, 1.0);
                this._drawPulses(ctx);
            }

            if (this.phase === 'EMBLEM_FORMED') {
                var ep  = Math.min(1, el / 1400);
                var eea = this._easeOut(ep);

                this._drawGridGhost(ctx, cx, cy, 0.04);
                this._drawTraces(ctx, 1.0, 0.2 + 0.07 * Math.sin(now * 0.003));
                this._drawNodes(ctx, 0.18);

                if (this.arcAlpha > 0) {
                    ctx.save();
                    ctx.globalAlpha = this.arcAlpha;
                    ctx.strokeStyle = '#00d4ff';
                    ctx.lineWidth   = 1.8;
                    for (var aa = 0; aa < 8; aa++) {
                        var ang = (aa / 8) * Math.PI * 2;
                        ctx.beginPath();
                        ctx.moveTo(cx + Math.cos(ang) * 22, cy + Math.sin(ang) * 22);
                        ctx.lineTo(cx + Math.cos(ang) * (52 + Math.random() * 18), cy + Math.sin(ang) * (52 + Math.random() * 18));
                        ctx.stroke();
                    }
                    ctx.restore();
                }

                if (this.shockwaveAlpha > 0) {
                    ctx.save();
                    ctx.globalAlpha = this.shockwaveAlpha;
                    ctx.strokeStyle = '#00a2e8';
                    ctx.lineWidth   = 2.5;
                    ctx.beginPath();
                    ctx.arc(cx, cy, this.shockwaveRadius, 0, Math.PI * 2);
                    ctx.stroke();
                    ctx.restore();
                }

                var embW = Math.min(245, W * 0.50);
                var embH = embW * (230 / 385);
                ctx.save();
                ctx.globalAlpha = eea;
                var sc = 0.65 + 0.35 * eea;
                ctx.translate(cx, cy);
                ctx.scale(sc, sc);
                ctx.translate(-cx, -cy);
                if (this.imgEmblem && this.imgEmblem.complete && this.imgEmblem.naturalWidth > 0) {
                    ctx.drawImage(this.imgEmblem, (W - embW) / 2, (H - embH) / 2, embW, embH);
                } else {
                    this._drawVectorEmblem(ctx, cx, cy, embW);
                }
                ctx.restore();
            }

            if (this.phase === 'ELABORATING') {
                var lp  = Math.min(1, el / 1900);
                var lea = this._easeInOut(lp);

                this._drawGridGhost(ctx, cx, cy, 0.028);
                this._drawTraces(ctx, 1.0, 0.11);

                var fullW = Math.min(440, W * 0.86);
                var fullH = fullW * (120 / 380);
                var fx    = (W - fullW) / 2;
                var fy    = (H - fullH) / 2;

                if (this.imgFull && this.imgFull.complete && this.imgFull.naturalWidth > 0) {
                    var revealX = fullW * lea;
                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(fx, fy - 6, revealX, fullH + 12);
                    ctx.clip();
                    ctx.drawImage(this.imgFull, fx, fy, fullW, fullH);
                    ctx.restore();

                    if (lea < 1) {
                        var bx = fx + revealX;
                        ctx.save();
                        var bGrad = ctx.createLinearGradient(bx - 14, 0, bx + 14, 0);
                        bGrad.addColorStop(0, 'rgba(0,162,232,0)');
                        bGrad.addColorStop(0.5, 'rgba(0,162,232,0.78)');
                        bGrad.addColorStop(1, 'rgba(0,162,232,0)');
                        ctx.fillStyle = bGrad;
                        ctx.fillRect(bx - 14, fy - 8, 28, fullH + 16);
                        ctx.restore();
                    }
                } else {
                    this._drawVectorEmblem(ctx, cx * 0.55, cy, fullW * 0.5);
                }
            }

            if (this.phase === 'COMPLETED') {
                this._drawGridGhost(ctx, cx, cy, 0.022);
                this._drawTraces(ctx, 1.0, 0.07);

                var cW = Math.min(440, W * 0.86);
                var cH = cW * (120 / 380);
                var cfx = (W - cW) / 2;
                var cfy = (H - cH) / 2;

                if (this.imgFull && this.imgFull.complete && this.imgFull.naturalWidth > 0) {
                    ctx.drawImage(this.imgFull, cfx, cfy, cW, cH);

                    var cycle  = (now % 5200) / 5200;
                    var sheenX = cfx + cW * cycle;
                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(cfx, cfy, cW, cH);
                    ctx.clip();
                    var sg = ctx.createLinearGradient(sheenX - 32, cfy, sheenX + 32, cfy + cH);
                    sg.addColorStop(0, 'rgba(255,255,255,0)');
                    sg.addColorStop(0.5, 'rgba(255,255,255,0.38)');
                    sg.addColorStop(1, 'rgba(255,255,255,0)');
                    ctx.fillStyle = sg;
                    ctx.fillRect(sheenX - 32, cfy, 64, cH);
                    ctx.restore();

                    var breath = 0.06 + 0.045 * Math.sin(this.breathPhase);
                    ctx.save();
                    ctx.globalAlpha = breath;
                    var glow = ctx.createRadialGradient(cx, cfy + cH + 18, 4, cx, cfy + cH + 18, cW * 0.52);
                    glow.addColorStop(0, '#00a2e8');
                    glow.addColorStop(1, 'rgba(0,162,232,0)');
                    ctx.fillStyle = glow;
                    ctx.fillRect(cfx - 40, cfy, cW + 80, cH + 50);
                    ctx.restore();
                } else {
                    this._drawVectorEmblem(ctx, cx, cy, cW * 0.5);
                }
            }

            for (var ri = 0; ri < this.chargeParticles.length; ri++) {
                var rp = this.chargeParticles[ri];
                if (rp.alpha <= 0) continue;
                ctx.save();
                ctx.globalAlpha = rp.alpha;
                ctx.fillStyle   = rp.color;
                ctx.shadowColor = rp.color;
                ctx.shadowBlur  = 7;
                ctx.beginPath();
                ctx.arc(rp.x, rp.y, rp.size, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }
        },

        _drawRadar(ctx, cx, cy) {
            var r = Math.min(this.width, this.height) * 0.44;
            var i, f, ang;

            ctx.save();
            ctx.strokeStyle = 'rgba(0,162,232,0.09)';
            ctx.lineWidth   = 0.8;
            var rings = [0.25, 0.5, 0.75, 1];
            for (i = 0; i < rings.length; i++) {
                ctx.beginPath();
                ctx.arc(cx, cy, r * rings[i], 0, Math.PI * 2);
                ctx.stroke();
            }
            ctx.strokeStyle = 'rgba(0,162,232,0.06)';
            ctx.beginPath(); ctx.moveTo(cx - r, cy); ctx.lineTo(cx + r, cy); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(cx, cy - r); ctx.lineTo(cx, cy + r); ctx.stroke();
            ctx.restore();

            if (this.rangePulseAlpha > 0) {
                ctx.save();
                ctx.globalAlpha = this.rangePulseAlpha * 0.5;
                ctx.strokeStyle = '#00a2e8';
                ctx.lineWidth   = 1.2;
                ctx.beginPath();
                ctx.arc(cx, cy, this.rangePulseR, 0, Math.PI * 2);
                ctx.stroke();
                ctx.restore();
            }

            var trailSpan = 0.28;
            for (i = 0; i < this.radarTrail.length; i++) {
                var t = this.radarTrail[i];
                ctx.save();
                ctx.globalAlpha = Math.max(0, t.alpha) * 0.45;
                ctx.fillStyle   = 'rgba(0,200,248,0.06)';
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.arc(cx, cy, r, t.angle - trailSpan, t.angle);
                ctx.closePath();
                ctx.fill();
                ctx.restore();
            }

            ctx.save();
            var armGrad = ctx.createLinearGradient(
                cx, cy,
                cx + Math.cos(this.radarAngle) * r,
                cy + Math.sin(this.radarAngle) * r
            );
            armGrad.addColorStop(0, 'rgba(0,200,248,0)');
            armGrad.addColorStop(1, 'rgba(0,200,248,0.88)');
            ctx.strokeStyle = armGrad;
            ctx.lineWidth   = 1.8;
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(this.radarAngle) * r, cy + Math.sin(this.radarAngle) * r);
            ctx.stroke();

            ctx.fillStyle   = '#00c8f8';
            ctx.shadowColor = '#00c8f8';
            ctx.shadowBlur  = 10;
            ctx.beginPath();
            ctx.arc(cx + Math.cos(this.radarAngle) * r * 0.98, cy + Math.sin(this.radarAngle) * r * 0.98, 2.5, 0, Math.PI * 2);
            ctx.fill();

            ctx.shadowBlur = 8;
            ctx.beginPath();
            ctx.arc(cx, cy, 3.5, 0, Math.PI * 2);
            ctx.fill();
            ctx.restore();
        },

        _drawGridGhost(ctx, cx, cy, alpha) {
            var r = Math.min(this.width, this.height) * 0.44;
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.strokeStyle = '#00a2e8';
            ctx.lineWidth   = 0.5;
            var rf = [0.25, 0.5, 0.75, 1];
            for (var i = 0; i < rf.length; i++) {
                ctx.beginPath(); ctx.arc(cx, cy, r * rf[i], 0, Math.PI * 2); ctx.stroke();
            }
            ctx.beginPath(); ctx.moveTo(cx - r, cy); ctx.lineTo(cx + r, cy); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(cx, cy - r); ctx.lineTo(cx, cy + r); ctx.stroke();
            ctx.restore();
        },

        _drawTraces(ctx, progress, alpha) {
            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.shadowColor = '#00c8f8';
            ctx.shadowBlur  = 6;
            for (var i = 0; i < this.traces.length; i++) {
                this._strokePartial(ctx, this.traces[i], progress, 2.4, '#00a2e8');
            }
            if (progress > 0.5) {
                var bp = (progress - 0.5) * 2;
                ctx.shadowBlur = 3;
                for (var j = 0; j < this.minorTraces.length; j++) {
                    this._strokePartial(ctx, this.minorTraces[j], bp, 1.1, 'rgba(0,162,232,0.52)');
                }
            }
            ctx.restore();
        },

        _drawNodes(ctx, alpha) {
            ctx.save();
            ctx.globalAlpha = alpha;
            for (var i = 0; i < this.nodes.length; i++) {
                var nd = this.nodes[i];
                ctx.fillStyle   = '#00a2e8';
                ctx.shadowColor = '#00c8f8';
                ctx.shadowBlur  = 8;
                ctx.beginPath();
                ctx.arc(nd.x, nd.y, nd.r, 0, Math.PI * 2);
                ctx.fill();
                ctx.strokeStyle = 'rgba(0,162,232,0.45)';
                ctx.lineWidth   = 0.8;
                ctx.beginPath();
                ctx.arc(nd.x, nd.y, nd.r + 2.8, 0, Math.PI * 2);
                ctx.stroke();
            }
            ctx.restore();
        },

        _drawPulses(ctx) {
            for (var i = 0; i < this.pulses.length; i++) {
                var p  = this.pulses[i];
                var pt = this._ptAlong(p.seg, p.t);
                ctx.save();
                ctx.fillStyle   = '#ffffff';
                ctx.shadowColor = p.color;
                ctx.shadowBlur  = 16;
                ctx.beginPath();
                ctx.arc(pt.x, pt.y, p.size, 0, Math.PI * 2);
                ctx.fill();
                ctx.fillStyle = p.color;
                ctx.shadowBlur = 6;
                ctx.beginPath();
                ctx.arc(pt.x, pt.y, p.size * 0.48, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }
        },

        _drawVectorEmblem(ctx, cx, cy, size) {
            var bw = size * 0.85, bh = size * 0.21;
            ctx.save();
            ctx.fillStyle   = '#00a2e8';
            ctx.shadowColor = '#00a2e8';
            ctx.shadowBlur  = 18;
            var offsets = [-size * 0.30, 0, size * 0.30];
            for (var i = 0; i < offsets.length; i++) {
                ctx.beginPath();
                ctx.roundRect(cx - bw / 2, cy + offsets[i] - bh / 2, bw, bh, [4, 18, 18, 4]);
                ctx.fill();
            }
            ctx.restore();
        },

        _ptAlong(pts, t) {
            var total = 0, i, lens = [];
            for (i = 1; i < pts.length; i++) {
                var l = Math.hypot(pts[i].x - pts[i-1].x, pts[i].y - pts[i-1].y);
                lens.push(l);
                total += l;
            }
            var rem = t * total;
            for (i = 0; i < lens.length; i++) {
                if (rem <= lens[i]) {
                    var f = rem / lens[i];
                    return {
                        x: pts[i].x + (pts[i+1].x - pts[i].x) * f,
                        y: pts[i].y + (pts[i+1].y - pts[i].y) * f
                    };
                }
                rem -= lens[i];
            }
            return pts[pts.length - 1];
        },

        _strokePartial(ctx, pts, t, lw, style) {
            if (pts.length < 2) return;
            var total = 0, i, lens = [];
            for (i = 1; i < pts.length; i++) {
                var l = Math.hypot(pts[i].x - pts[i-1].x, pts[i].y - pts[i-1].y);
                lens.push(l);
                total += l;
            }
            var rem = t * total;
            ctx.save();
            ctx.strokeStyle = style;
            ctx.lineWidth   = lw;
            ctx.lineCap     = 'round';
            ctx.lineJoin    = 'round';
            ctx.beginPath();
            ctx.moveTo(pts[0].x, pts[0].y);
            for (i = 0; i < lens.length; i++) {
                if (rem <= 0) break;
                if (rem >= lens[i]) {
                    ctx.lineTo(pts[i+1].x, pts[i+1].y);
                    rem -= lens[i];
                } else {
                    var f2 = rem / lens[i];
                    ctx.lineTo(
                        pts[i].x + (pts[i+1].x - pts[i].x) * f2,
                        pts[i].y + (pts[i+1].y - pts[i].y) * f2
                    );
                    break;
                }
            }
            ctx.stroke();
            ctx.restore();
        },

        _easeInOut(t) { return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2,3)/2; },
        _easeOut(t)   { return 1 - Math.pow(1-t, 3); }
    };

    // Expose globally — both the canonical and legacy names
    window.RadarPCBEngine     = Engine;
    window.FallingBooksEngine = Engine;   // keep external API intact

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() { Engine.init(); });
    } else {
        Engine.init();
    }
})();
