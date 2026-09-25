/**
 * ====================================================================
 * BEL Library Management System - Next-Gen Vanilla UI Engine
 * Features: Command Palette (Ctrl+K), Spotlight Tracking, 3D Tilt,
 * Slide-Over Drawer, SVG Sparklines, Radial Gauges, Keyboard HUD.
 * 100% Pure ES6+ Vanilla JavaScript - Zero Dependencies
 * ====================================================================
 */

(function () {
    'use strict';

    // --- State Storage ---
    const APP_STATE = {
        theme: localStorage.getItem('bel_theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'),
        activeCatalogView: localStorage.getItem('bel_catalog_view') || 'grid',
        keySequence: [],
        lastKeyTime: 0
    };

    // ====================================================================
    // 1. THEME MANAGER
    // ====================================================================
    const ThemeManager = {
        init() {
            this.applyTheme(APP_STATE.theme);
            const toggleBtns = document.querySelectorAll('[data-theme-toggle]');
            toggleBtns.forEach(btn => {
                btn.addEventListener('click', () => this.toggleTheme());
            });
        },

        applyTheme(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            APP_STATE.theme = theme;
            localStorage.setItem('bel_theme', theme);
            this.updateIcons(theme);
        },

        toggleTheme() {
            const nextTheme = APP_STATE.theme === 'dark' ? 'light' : 'dark';
            this.applyTheme(nextTheme);
            ToastManager.show(`Switched to ${nextTheme === 'dark' ? 'Obsidian Dark' : 'Studio Light'} mode`, 'info');
        },

        updateIcons(theme) {
            const toggleBtns = document.querySelectorAll('[data-theme-toggle]');
            toggleBtns.forEach(btn => {
                btn.innerHTML = theme === 'dark'
                    ? `<svg width="19" height="19" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>`
                    : `<svg width="19" height="19" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>`;
            });
        }
    };

    // ====================================================================
    // 2. CURSOR SPOTLIGHT TRACKING ENGINE
    // ====================================================================
    const SpotlightEngine = {
        init() {
            document.addEventListener('mousemove', (e) => {
                const cards = document.querySelectorAll('.spotlight-card, .bento-card, .book-card-3d');
                cards.forEach(card => {
                    const rect = card.getBoundingClientRect();
                    const x = e.clientX - rect.left;
                    const y = e.clientY - rect.top;
                    card.style.setProperty('--mouse-x', `${x}px`);
                    card.style.setProperty('--mouse-y', `${y}px`);
                });
            });
        }
    };

    // ====================================================================
    // 3. 3D CARD PERSPECTIVE TILT
    // ====================================================================
    const TiltEngine = {
        init() {
            const tiltElements = document.querySelectorAll('.book-card-3d, [data-tilt]');
            tiltElements.forEach(el => {
                el.addEventListener('mousemove', (e) => {
                    const rect = el.getBoundingClientRect();
                    const x = e.clientX - rect.left;
                    const y = e.clientY - rect.top;
                    const centerX = rect.width / 2;
                    const centerY = rect.height / 2;
                    const rotateX = ((y - centerY) / centerY) * -7;
                    const rotateY = ((x - centerX) / centerX) * 7;
                    el.style.transform = `perspective(800px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
                });

                el.addEventListener('mouseleave', () => {
                    el.style.transform = '';
                });
            });
        }
    };

    // ====================================================================
    // 4. GLOBAL COMMAND PALETTE (Ctrl + K / Cmd + K)
    // ====================================================================
    const CommandPalette = {
        backdrop: null,
        input: null,
        results: null,
        selectedIndex: 0,
        items: [],

        init() {
            this.backdrop = document.getElementById('cmdPaletteBackdrop');
            this.input = document.getElementById('cmdPaletteInput');
            this.results = document.getElementById('cmdPaletteResults');

            if (!this.backdrop || !this.input) return;

            // Trigger buttons
            document.querySelectorAll('[data-open-cmd]').forEach(btn => {
                btn.addEventListener('click', () => this.open());
            });

            // Input typing
            this.input.addEventListener('input', () => this.handleFilter());

            // Keyboard navigation in modal
            this.input.addEventListener('keydown', (e) => this.handleKeydown(e));

            // Backdrop click to close
            this.backdrop.addEventListener('click', (e) => {
                if (e.target === this.backdrop) this.close();
            });

            // Global shortcut listener: Ctrl+K or Cmd+K
            document.addEventListener('keydown', (e) => {
                if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
                    e.preventDefault();
                    if (this.isOpen()) {
                        this.close();
                    } else {
                        this.open();
                    }
                }
            });
        },

        isOpen() {
            return this.backdrop && this.backdrop.classList.contains('open');
        },

        open() {
            this.buildIndex();
            this.selectedIndex = 0;
            this.backdrop.classList.add('open');
            this.input.value = '';
            this.renderItems(this.items);
            setTimeout(() => this.input.focus(), 50);
        },

        close() {
            if (this.backdrop) {
                this.backdrop.classList.remove('open');
            }
        },

        buildIndex() {
            this.items = [
                // Navigation Links
                { group: 'Navigation', title: 'Dashboard', desc: 'Overview, analytics & KPIs', url: 'dashboard.asp', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' },
                { group: 'Navigation', title: 'Books Catalog', desc: 'Browse catalog, stock & inventory', url: 'books.asp', icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253' },
                { group: 'Navigation', title: 'Borrowings & Loans', desc: 'Issue desk & return handling', url: 'borrowings.asp', icon: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' },
                { group: 'Navigation', title: 'Reservation Requests', desc: 'Manage member book requests', url: 'requests.asp', icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2' },
                { group: 'Navigation', title: 'Authors Directory', desc: 'View and manage book authors', url: 'authors.asp', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
                { group: 'Navigation', title: 'Categories / Genres', desc: 'Manage book taxonomy classifications', url: 'categories.asp', icon: 'M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z' },
                { group: 'Navigation', title: 'User Feedbacks & Reviews', desc: 'Read member book reviews and ratings', url: 'feedback.asp', icon: 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z' },
                // Quick Actions
                { group: 'Actions', title: '+ Add New Book', desc: 'Catalog a new book into inventory', url: 'books_add.asp', icon: 'M12 4v16m8-8H4' },
                { group: 'Actions', title: 'Toggle Dark / Light Theme', desc: 'Switch interface contrast theme', action: () => ThemeManager.toggleTheme(), icon: 'M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z' },
                { group: 'Actions', title: 'Sign Out / Logout', desc: 'Securely end your session', url: 'logout.asp', icon: 'M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1' }
            ];

            // Scrape on-page book items if available
            document.querySelectorAll('[data-book-json]').forEach(el => {
                try {
                    const data = JSON.parse(el.getAttribute('data-book-json'));
                    this.items.push({
                        group: 'Books On Page',
                        title: data.title,
                        desc: `${data.author} • ${data.category}`,
                        action: () => SlideOverDrawer.open(data),
                        icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253'
                    });
                } catch (e) {}
            });
        },

        handleFilter() {
            const query = this.input.value.trim().toLowerCase();
            if (!query) {
                this.renderItems(this.items);
                return;
            }

            const filtered = this.items.filter(item => {
                return item.title.toLowerCase().includes(query) ||
                       (item.desc && item.desc.toLowerCase().includes(query));
            });

            this.selectedIndex = 0;
            this.renderItems(filtered);
        },

        renderItems(itemsList) {
            if (!this.results) return;
            if (itemsList.length === 0) {
                this.results.innerHTML = `<div style="padding:24px; text-align:center; color:var(--text-muted); font-size:13.5px;">No matching results found for "${this.escapeHtml(this.input.value)}"</div>`;
                return;
            }

            let html = '';
            let currentGroup = '';

            itemsList.forEach((item, index) => {
                if (item.group !== currentGroup) {
                    currentGroup = item.group;
                    html += `<div class="cmd-group-label">${currentGroup}</div>`;
                }

                const isSelected = index === this.selectedIndex ? 'selected' : '';
                html += `
                    <div class="cmd-item ${isSelected}" data-index="${index}">
                        <div class="cmd-item-left">
                            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="${item.icon}" /></svg>
                            <div>
                                <div>${this.escapeHtml(item.title)}</div>
                                ${item.desc ? `<div style="font-size:11.5px; opacity:0.7;">${this.escapeHtml(item.desc)}</div>` : ''}
                            </div>
                        </div>
                        <span class="cmd-item-badge">${item.group}</span>
                    </div>
                `;
            });

            this.results.innerHTML = html;

            // Click listener
            this.results.querySelectorAll('.cmd-item').forEach(el => {
                el.addEventListener('click', () => {
                    const idx = parseInt(el.getAttribute('data-index'), 10);
                    this.executeItem(itemsList[idx]);
                });
            });
        },

        handleKeydown(e) {
            const renderedItems = this.results.querySelectorAll('.cmd-item');
            if (renderedItems.length === 0) return;

            if (e.key === 'ArrowDown') {
                e.preventDefault();
                this.selectedIndex = (this.selectedIndex + 1) % renderedItems.length;
                this.updateSelection(renderedItems);
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                this.selectedIndex = (this.selectedIndex - 1 + renderedItems.length) % renderedItems.length;
                this.updateSelection(renderedItems);
            } else if (e.key === 'Enter') {
                e.preventDefault();
                const selected = renderedItems[this.selectedIndex];
                if (selected) {
                    selected.click();
                }
            } else if (e.key === 'Escape') {
                this.close();
            }
        },

        updateSelection(elements) {
            elements.forEach((el, i) => {
                if (i === this.selectedIndex) {
                    el.classList.add('selected');
                    el.scrollIntoView({ block: 'nearest' });
                } else {
                    el.classList.remove('selected');
                }
            });
        },

        executeItem(item) {
            this.close();
            if (!item) return;
            if (item.action) {
                item.action();
            } else if (item.url) {
                window.location.href = item.url;
            }
        },

        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text || '';
            return div.innerHTML;
        }
    };

    // ====================================================================
    // 5. SLIDE-OVER DETAIL INSPECTOR DRAWER
    // ====================================================================
    const SlideOverDrawer = {
        backdrop: null,
        drawer: null,
        titleEl: null,
        bodyEl: null,
        footerEl: null,

        init() {
            this.backdrop = document.getElementById('slideOverBackdrop');
            if (!this.backdrop) return;

            this.drawer = this.backdrop.querySelector('.slide-over-drawer');
            this.titleEl = document.getElementById('drawerTitle');
            this.bodyEl = document.getElementById('drawerBody');
            this.footerEl = document.getElementById('drawerFooter');

            const closeBtn = document.getElementById('drawerCloseBtn');
            if (closeBtn) {
                closeBtn.addEventListener('click', () => this.close());
            }

            this.backdrop.addEventListener('click', (e) => {
                if (e.target === this.backdrop) this.close();
            });

            // Attach to all elements with data-book-json
            document.querySelectorAll('[data-book-trigger]').forEach(trigger => {
                trigger.addEventListener('click', (e) => {
                    const card = trigger.closest('[data-book-json]');
                    if (card) {
                        try {
                            const data = JSON.parse(card.getAttribute('data-book-json'));
                            this.open(data);
                        } catch (err) {}
                    }
                });
            });
        },

        open(book) {
            if (!this.backdrop || !book) return;

            this.titleEl.textContent = book.title;

            const isAvailable = (book.available_copies || 0) > 0;
            const stockBadge = isAvailable
                ? `<span class="badge badge-success"><span class="badge-dot"></span>${book.available_copies} in stock</span>`
                : `<span class="badge badge-danger"><span class="badge-dot"></span>Out of stock</span>`;

            this.bodyEl.innerHTML = `
                <!-- 3D Mini Book Display -->
                <div style="background:var(--bg-surface-subtle); border-radius:var(--radius-lg); padding:24px; display:flex; gap:20px; align-items:center;">
                    <div class="book-3d-model" style="width:110px; height:150px; flex-shrink:0;">
                        <div class="book-front-cover">
                            <span class="book-cover-badge">${book.category || 'Literature'}</span>
                            <div class="book-cover-title" style="font-size:12px;">${book.title}</div>
                            <div class="book-cover-author">${book.author}</div>
                        </div>
                    </div>
                    <div style="flex:1;">
                        <div style="font-size:11px; font-weight:700; color:var(--brand-primary); text-transform:uppercase; margin-bottom:4px;">${book.category || 'BEL Library'}</div>
                        <h3 style="font-size:17px; font-weight:800; color:var(--text-primary); margin-bottom:6px; line-height:1.3;">${book.title}</h3>
                        <div style="font-size:13px; color:var(--text-secondary); margin-bottom:12px;">Author: <strong>${book.author}</strong></div>
                        <div>${stockBadge}</div>
                    </div>
                </div>

                <!-- Metadata Grid -->
                <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                    <div style="background:var(--bg-surface-subtle); border:1px solid var(--border-subtle); border-radius:var(--radius-md); padding:12px 14px;">
                        <div style="font-size:11px; color:var(--text-muted); font-weight:700; text-transform:uppercase;">ISBN Code</div>
                        <code style="font-size:12.5px; font-weight:700; color:var(--text-primary); margin-top:2px; display:block;">${book.isbn || 'N/A'}</code>
                    </div>
                    <div style="background:var(--bg-surface-subtle); border:1px solid var(--border-subtle); border-radius:var(--radius-md); padding:12px 14px;">
                        <div style="font-size:11px; color:var(--text-muted); font-weight:700; text-transform:uppercase;">Publisher</div>
                        <div style="font-size:13px; font-weight:600; color:var(--text-primary); margin-top:2px;">${book.publisher || 'General Circulation'}</div>
                    </div>
                    <div style="background:var(--bg-surface-subtle); border:1px solid var(--border-subtle); border-radius:var(--radius-md); padding:12px 14px;">
                        <div style="font-size:11px; color:var(--text-muted); font-weight:700; text-transform:uppercase;">Total Copies</div>
                        <div style="font-size:16px; font-weight:800; color:var(--text-primary); margin-top:2px;">${book.total_copies || 1}</div>
                    </div>
                    <div style="background:var(--bg-surface-subtle); border:1px solid var(--border-subtle); border-radius:var(--radius-md); padding:12px 14px;">
                        <div style="font-size:11px; color:var(--text-muted); font-weight:700; text-transform:uppercase;">Replacement Fee</div>
                        <div style="font-size:16px; font-weight:800; color:var(--success); margin-top:2px;">&#8377;${book.price || '0.00'}</div>
                    </div>
                </div>

                <!-- Circulation Policy Note -->
                <div style="padding:14px; border-radius:var(--radius-md); background:rgba(99,102,241,0.08); border:1px solid rgba(99,102,241,0.2); font-size:12.5px; color:var(--text-secondary); line-height:1.5;">
                    <strong style="color:var(--brand-primary);">BEL Lending Rule:</strong> Active members may loan this title for a maximum duration of 15 calendar days. Reservations hold items at the circulation desk for 48 hours.
                </div>
            `;

            this.footerEl.innerHTML = `
                <a href="feedback.asp?book_id=${book.id}" class="btn btn-secondary btn-sm">★ Rate & Review</a>
                ${book.can_edit ? `<a href="books_edit.asp?id=${book.id}" class="btn btn-secondary btn-sm">Edit Book</a>` : ''}
                ${isAvailable ? `<a href="request_book.asp?id=${book.id}" class="btn btn-primary btn-sm">⚡ Reserve Now</a>` : `<button class="btn btn-outline btn-sm" disabled>Out of Stock</button>`}
            `;

            this.backdrop.classList.add('open');
        },

        close() {
            if (this.backdrop) {
                this.backdrop.classList.remove('open');
            }
        }
    };

    // ====================================================================
    // 6. PURE SVG SPARKLINE GENERATOR (Weekly Lending Velocity)
    // ====================================================================
    const SparklineEngine = {
        init() {
            document.querySelectorAll('[data-sparkline]').forEach(el => {
                try {
                    const points = JSON.parse(el.getAttribute('data-sparkline') || '[]');
                    if (!points || points.length < 2) return;
                    this.render(el, points);
                } catch (e) {}
            });
        },

        render(container, data) {
            const width = 340;
            const height = 65;
            const min = Math.min(...data);
            const max = Math.max(...data) || 1;
            const range = max - min || 1;

            const coords = data.map((val, i) => {
                const x = (i / (data.length - 1)) * (width - 16) + 8;
                const y = height - 10 - ((val - min) / range) * (height - 24);
                return [x, y];
            });

            // Smooth cubic Bézier curve path
            let d = `M ${coords[0][0]},${coords[0][1]}`;
            for (let i = 0; i < coords.length - 1; i++) {
                const curr = coords[i];
                const next = coords[i + 1];
                const cp1x = curr[0] + (next[0] - curr[0]) / 2;
                const cp1y = curr[1];
                const cp2x = curr[0] + (next[0] - curr[0]) / 2;
                const cp2y = next[1];
                d += ` C ${cp1x},${cp1y} ${cp2x},${cp2y} ${next[0]},${next[1]}`;
            }

            const fillPath = `${d} L ${coords[coords.length - 1][0]},${height} L ${coords[0][0]},${height} Z`;

            container.innerHTML = `
                <svg viewBox="0 0 ${width} ${height}" preserveAspectRatio="none">
                    <defs>
                        <linearGradient id="sparkGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="0%" stop-color="#4f46e5" stop-opacity="0.32" />
                            <stop offset="100%" stop-color="#4f46e5" stop-opacity="0.0" />
                        </linearGradient>
                    </defs>
                    <path d="${fillPath}" fill="url(#sparkGrad)" />
                    <path d="${d}" fill="none" stroke="#4f46e5" stroke-width="2.5" stroke-linecap="round" />
                    ${coords.map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3" fill="#4f46e5" />`).join('')}
                </svg>
            `;
        }
    };

    // ====================================================================
    // 7. PURE SVG RADIAL GAUGE GENERATOR (Circulation Utilization)
    // ====================================================================
    const RadialGaugeEngine = {
        init() {
            document.querySelectorAll('[data-radial-gauge]').forEach(el => {
                const total = parseInt(el.getAttribute('data-total') || '10', 10);
                const active = parseInt(el.getAttribute('data-active') || '0', 10);
                const percent = total > 0 ? Math.min(100, Math.round((active / total) * 100)) : 0;

                const radius = 45;
                const circumference = 2 * Math.PI * radius;
                const offset = circumference - (percent / 100) * circumference;

                el.innerHTML = `
                    <div class="radial-gauge-wrap">
                        <div style="position:relative; width:110px; height:110px; display:flex; align-items:center; justify-content:center;">
                            <svg class="radial-gauge-svg" viewBox="0 0 110 110">
                                <defs>
                                    <linearGradient id="radialGrad" x1="0" y1="0" x2="1" y2="1">
                                        <stop offset="0%" stop-color="#4f46e5" />
                                        <stop offset="100%" stop-color="#06b6d4" />
                                    </linearGradient>
                                </defs>
                                <circle class="radial-gauge-track" cx="55" cy="55" r="${radius}" />
                                <circle class="radial-gauge-bar" cx="55" cy="55" r="${radius}"
                                    stroke-dasharray="${circumference}"
                                    stroke-dashoffset="${offset}" />
                            </svg>
                            <div style="position:absolute; text-align:center;">
                                <span style="font-size:22px; font-weight:800; color:var(--text-primary); letter-spacing:-0.03em;">${percent}%</span>
                            </div>
                        </div>
                        <div class="gauge-stats">
                            <div style="font-size:12px; color:var(--text-muted); font-weight:700; text-transform:uppercase;">Circulation Ratio</div>
                            <div style="font-size:14px; color:var(--text-primary); font-weight:600;">
                                <strong style="color:var(--brand-primary);">${active}</strong> active of <strong style="color:var(--text-primary);">${total}</strong> total inventory
                            </div>
                            <span class="badge ${percent > 0 ? 'badge-info' : 'badge-success'}" style="width:fit-content; margin-top:2px;">
                                <span class="badge-dot"></span>${percent > 0 ? 'Active Loans Running' : '100% Stock Available'}
                            </span>
                        </div>
                    </div>
                `;
            });
        }
    };

    // ====================================================================
    // 8. KEYBOARD SHORTCUTS ENGINE & HUD (?)
    // ====================================================================
    const KeyboardEngine = {
        hudModal: null,

        init() {
            this.hudModal = document.getElementById('shortcutsModalBackdrop');

            // Close button
            const closeBtn = document.getElementById('shortcutsCloseBtn');
            if (closeBtn) closeBtn.addEventListener('click', () => this.closeHud());

            if (this.hudModal) {
                this.hudModal.addEventListener('click', (e) => {
                    if (e.target === this.hudModal) this.closeHud();
                });
            }

            document.addEventListener('keydown', (e) => {
                // If user is typing in an input or textarea, ignore shortcuts (except Escape)
                const isInput = ['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName);

                if (e.key === 'Escape') {
                    CommandPalette.close();
                    SlideOverDrawer.close();
                    this.closeHud();
                    return;
                }

                if (isInput) return;

                // '?' opens shortcuts HUD
                if (e.key === '?') {
                    e.preventDefault();
                    this.toggleHud();
                    return;
                }

                // '/' focuses search or opens command palette
                if (e.key === '/') {
                    e.preventDefault();
                    CommandPalette.open();
                    return;
                }

                // 't' toggles theme
                if (e.key.toLowerCase() === 't') {
                    e.preventDefault();
                    ThemeManager.toggleTheme();
                    return;
                }

                // Sequence shortcuts (g then d, g then b, g then r)
                const now = Date.now();
                if (now - APP_STATE.lastKeyTime > 1000) {
                    APP_STATE.keySequence = [];
                }
                APP_STATE.lastKeyTime = now;
                APP_STATE.keySequence.push(e.key.toLowerCase());

                if (APP_STATE.keySequence.length >= 2) {
                    const seq = APP_STATE.keySequence.slice(-2).join('');
                    if (seq === 'gd') window.location.href = 'dashboard.asp';
                    if (seq === 'gb') window.location.href = 'books.asp';
                    if (seq === 'gr') window.location.href = 'requests.asp';
                    if (seq === 'gl') window.location.href = 'borrowings.asp';
                    APP_STATE.keySequence = [];
                }
            });
        },

        toggleHud() {
            if (this.hudModal) {
                this.hudModal.classList.toggle('open');
            }
        },

        closeHud() {
            if (this.hudModal) {
                this.hudModal.classList.remove('open');
            }
        }
    };

    // ====================================================================
    // 9. THREE-WAY CATALOG VIEW TOGGLE (Grid, Table, Compact)
    // ====================================================================
    const ViewToggle = {
        init() {
            const btnGrid = document.getElementById('btnViewGrid');
            const btnTable = document.getElementById('btnViewTable');
            const btnCompact = document.getElementById('btnViewCompact');

            const viewGrid = document.getElementById('catalogGridView');
            const viewTable = document.getElementById('catalogTableView');
            const viewCompact = document.getElementById('catalogCompactView');

            if (!viewGrid || !viewTable) return;

            const applyView = (mode) => {
                APP_STATE.activeCatalogView = mode;
                localStorage.setItem('bel_catalog_view', mode);

                if (viewGrid) viewGrid.style.display = mode === 'grid' ? 'grid' : 'none';
                if (viewTable) viewTable.style.display = mode === 'table' ? 'block' : 'none';
                if (viewCompact) viewCompact.style.display = mode === 'compact' ? 'flex' : 'none';

                if (btnGrid) btnGrid.className = mode === 'grid' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm';
                if (btnTable) btnTable.className = mode === 'table' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm';
                if (btnCompact) btnCompact.className = mode === 'compact' ? 'btn btn-primary btn-sm' : 'btn btn-secondary btn-sm';
            };

            if (btnGrid) btnGrid.addEventListener('click', () => applyView('grid'));
            if (btnTable) btnTable.addEventListener('click', () => applyView('table'));
            if (btnCompact) btnCompact.addEventListener('click', () => applyView('compact'));

            applyView(APP_STATE.activeCatalogView);
        }
    };

    // ====================================================================
    // 10. MULTI-FACET FILTER PILLS BAR
    // ====================================================================
    const MultiFacetFilter = {
        init() {
            const pills = document.querySelectorAll('.filter-pill');
            if (pills.length === 0) return;

            pills.forEach(pill => {
                pill.addEventListener('click', () => {
                    pills.forEach(p => p.classList.remove('active'));
                    pill.classList.add('active');

                    const categoryFilter = pill.getAttribute('data-filter') || 'all';
                    this.filterCatalog(categoryFilter);
                });
            });
        },

        filterCatalog(filterValue) {
            const items = document.querySelectorAll('[data-book-json]');
            items.forEach(item => {
                try {
                    const data = JSON.parse(item.getAttribute('data-book-json'));
                    const category = (data.category || '').toLowerCase();
                    const available = (data.available_copies || 0) > 0;

                    let show = true;
                    if (filterValue === 'all') {
                        show = true;
                    } else if (filterValue === 'available') {
                        show = available;
                    } else if (filterValue === 'kannada') {
                        show = category.includes('kannada') || category.includes('ಕನ್ನಡ');
                    } else {
                        show = category.includes(filterValue.toLowerCase());
                    }

                    item.style.display = show ? '' : 'none';
                } catch (e) {}
            });
        }
    };

    // ====================================================================
    // 11. INSTANT LIVE SEARCH & TABLE SORTER
    // ====================================================================
    const LiveTableFilter = {
        init() {
            document.querySelectorAll('[data-live-filter]').forEach(input => {
                const targetId = input.getAttribute('data-live-filter');
                const targetEl = document.getElementById(targetId);
                if (!targetEl) return;

                input.addEventListener('input', () => {
                    const q = input.value.trim().toLowerCase();
                    const rows = targetEl.querySelectorAll('tbody tr, .book-card-3d, .compact-book-row');
                    rows.forEach(row => {
                        const text = row.innerText.toLowerCase();
                        row.style.display = text.includes(q) ? '' : 'none';
                    });
                });
            });
        }
    };

    const TableSorter = {
        init() {
            document.querySelectorAll('th.sortable').forEach(header => {
                header.addEventListener('click', () => {
                    const table = header.closest('table');
                    const tbody = table.querySelector('tbody');
                    const colIndex = Array.from(header.parentNode.children).indexOf(header);
                    const isAsc = header.getAttribute('data-sort') !== 'asc';

                    header.parentNode.querySelectorAll('th').forEach(th => th.removeAttribute('data-sort'));
                    header.setAttribute('data-sort', isAsc ? 'asc' : 'desc');

                    const rows = Array.from(tbody.querySelectorAll('tr'));
                    rows.sort((a, b) => {
                        const cellA = (a.children[colIndex] ? a.children[colIndex].innerText : '').trim();
                        const cellB = (b.children[colIndex] ? b.children[colIndex].innerText : '').trim();
                        const numA = parseFloat(cellA.replace(/[^0-9.-]+/g, ''));
                        const numB = parseFloat(cellB.replace(/[^0-9.-]+/g, ''));

                        if (!isNaN(numA) && !isNaN(numB)) {
                            return isAsc ? numA - numB : numB - numA;
                        }
                        return isAsc ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
                    });

                    rows.forEach(r => tbody.appendChild(r));
                });
            });
        }
    };

    // ====================================================================
    // 12. TOAST ALERTS & DEMO LOGIN PILLS
    // ====================================================================
    const ToastManager = {
        container: null,

        show(message, type = 'info', duration = 3500) {
            if (!this.container) {
                this.container = document.getElementById('toastContainer');
                if (!this.container) {
                    this.container = document.createElement('div');
                    this.container.id = 'toastContainer';
                    this.container.className = 'toast-container';
                    document.body.appendChild(this.container);
                }
            }

            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;
            toast.innerHTML = `
                <div style="width:8px; height:8px; border-radius:50%; background:var(--${type === 'info' ? 'brand-primary' : type}); flex-shrink:0;"></div>
                <div style="font-size:13.5px; font-weight:500;">${message}</div>
            `;

            this.container.appendChild(toast);
            setTimeout(() => {
                toast.style.opacity = '0';
                toast.style.transform = 'translateY(10px)';
                setTimeout(() => toast.remove(), 250);
            }, duration);
        }
    };

    const DemoLogin = {
        init() {
            document.querySelectorAll('[data-demo-staff], [data-demo-email]').forEach(pill => {
                pill.addEventListener('click', () => {
                    const staff = pill.getAttribute('data-demo-staff') || pill.getAttribute('data-demo-email');
                    const pass = pill.getAttribute('data-demo-dob') || pill.getAttribute('data-demo-pass');
                    const staffInput = document.getElementById('loginStaffNumber') || document.getElementById('loginEmail');
                    const passInput = document.getElementById('loginPassword');

                    if (staffInput && passInput) {
                        staffInput.value = staff;
                        passInput.value = pass;
                        ToastManager.show(`Autofilled: ${staff} (${pill.innerText.trim()})`, 'success');
                    }
                });
            });
        }
    };

    // ====================================================================
    // 13. MOBILE SIDEBAR DRAWER TOGGLE
    // ====================================================================
    const MobileSidebar = {
        init() {
            const toggleBtn = document.getElementById('mobileSidebarToggle');
            const sidebar = document.getElementById('appSidebar');

            if (toggleBtn && sidebar) {
                toggleBtn.addEventListener('click', () => {
                    sidebar.classList.toggle('mobile-open');
                });

                document.addEventListener('click', (e) => {
                    if (sidebar.classList.contains('mobile-open') &&
                        !sidebar.contains(e.target) &&
                        !toggleBtn.contains(e.target)) {
                        sidebar.classList.remove('mobile-open');
                    }
                });
            }
        }
    };

    // ====================================================================
    // 14. RADAR SWEEP & PCB CIRCUIT -> BEL LOGO TRANSFORMATION ENGINE
    // ====================================================================
    const FallingBooksEngine = {
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

        // Phase state machine
        // RADAR -> TRACING -> CHARGING -> EMBLEM_FORMED -> ELABORATING -> COMPLETED
        phase: 'RADAR',
        phaseStartTime: 0,

        // --- Radar state ---
        radarAngle: -Math.PI / 2,   // starts pointing up
        radarTrail: [],             // [{angle, alpha}]
        rangePulseR: 0,
        rangePulseAlpha: 0,

        // --- Circuit trace state ---
        traces: [],      // fully defined trace paths
        traceProgress: 0, // 0..1 how far along drawing is complete
        nodes: [],       // solder-point nodes

        // --- Charging state ---
        pulses: [],      // data pulse objects travelling along highways
        chargeParticles: [],
        arcFlash: 0,
        arcAlpha: 0,

        // --- Shockwave ---
        shockwaveRadius: 0,
        shockwaveAlpha: 0,

        // --- Emblem breathing ---
        breathPhase: 0,

        // Compatibility shim: old "books" field used nowhere but kept safe
        books: [],
        particles: [],

        catalog: [
            { title: "BEL Defense Radar & EW", bg: ["#0284c7", "#0369a1"], spine: "#38bdf8", ribbon: "#bae6fd", w: 180, h: 30 },
            { title: "ಭಾರತ ಎಲೆಕ್ಟ್ರಾನಿಕ್ಸ್ ಸಂಶೋಧನೆ", bg: ["#0369a1", "#075985"], spine: "#7dd3fc", ribbon: "#fef08a", w: 195, h: 32 },
            { title: "Avionics Microcircuits & VLSI", bg: ["#075985", "#0c4a6e"], spine: "#38bdf8", ribbon: "#e0f2fe", w: 185, h: 30 },
            { title: "ಕನ್ನಡ ತಾಂತ್ರಿಕ ಗ್ರಂಥಾಲಯ", bg: ["#1e3a8a", "#172554"], spine: "#93c5fd", ribbon: "#fde047", w: 175, h: 28 },
            { title: "Sonar Acoustic Processing", bg: ["#0284c7", "#0f172a"], spine: "#67e8f9", ribbon: "#cffafe", w: 190, h: 32 },
            { title: "ರಕ್ಷಣಾ ಸಂವಹನ ವ್ಯವಸ್ಥೆಗಳು", bg: ["#0c4a6e", "#082f49"], spine: "#38bdf8", ribbon: "#fef9c3", w: 180, h: 30 },
            { title: "Optics & Laser Rangefinders", bg: ["#0369a1", "#0f2b5c"], spine: "#60a5fa", ribbon: "#dbeafe", w: 185, h: 30 },
            { title: "Military Satellite Telemetry", bg: ["#1d4ed8", "#1e3a8a"], spine: "#93c5fd", ribbon: "#e0e7ff", w: 190, h: 32 },
            { title: "ಕುವೆಂಪು ಸಮಗ್ರ ಸಾಹಿತ್ಯ ಸಂಪುಟ", bg: ["#0f766e", "#115e59"], spine: "#5eead4", ribbon: "#ccfbf1", w: 180, h: 30 },
            { title: "Digital Signal Micro-Arrays", bg: ["#0284c7", "#0369a1"], spine: "#38bdf8", ribbon: "#bae6fd", w: 185, h: 30 },
            { title: "Electronic Countermeasures", bg: ["#075985", "#0f172a"], spine: "#7dd3fc", ribbon: "#fde047", w: 190, h: 32 },
            { title: "ತಂತ್ರಜ್ಞಾನ ಮತ್ತು ಭಾರತೀಯ ರಕ್ಷಣೆ", bg: ["#1e3a8a", "#0f172a"], spine: "#93c5fd", ribbon: "#fed7aa", w: 180, h: 28 },
            { title: "Autonomous Tactical Systems", bg: ["#0369a1", "#0c4a6e"], spine: "#38bdf8", ribbon: "#e0f2fe", w: 185, h: 30 },
            { title: "ಪರ್ವ - ಮಹಾಭಾರತದ ಮರುವ್ಯಾಖ್ಯಾನ", bg: ["#0f766e", "#134e4a"], spine: "#6ee7b7", ribbon: "#d1fae5", w: 180, h: 30 },
            { title: "Missile Guidance & Navigation", bg: ["#0284c7", "#1e40af"], spine: "#60a5fa", ribbon: "#bfdbfe", w: 195, h: 32 },
            { title: "Quantum Key Cryptography", bg: ["#172554", "#090d16"], spine: "#93c5fd", ribbon: "#c7d2fe", w: 175, h: 28 },
            { title: "ಭಾರತೀಯ ಇಂಜಿನಿಯರಿಂಗ್ ಪರಂಪರೆ", bg: ["#0369a1", "#082f49"], spine: "#38bdf8", ribbon: "#fef08a", w: 185, h: 30 },
            { title: "Electromagnetic Defense OS", bg: ["#0284c7", "#0c4a6e"], spine: "#7dd3fc", ribbon: "#e0f2fe", w: 190, h: 32 }
        ],

        init() {
            // Delegated to RadarPCBEngine loaded by radar-pcb-engine.js
            // RadarPCBEngine already self-inits and patches window.FallingBooksEngine
            if (window.RadarPCBEngine && typeof window.RadarPCBEngine.init === 'function') {
                // Already initialised by radar-pcb-engine.js — nothing to do here
                return;
            }
        },

        loadImages() {
            let loadedCount = 0;
            const onImgLoad = () => {
                loadedCount++;
                if (loadedCount >= 2) {
                    this.imagesReady = true;
                }
            };

            this.imgEmblem = new Image();
            this.imgEmblem.onload = onImgLoad;
            this.imgEmblem.src = (window.BEL_ASSETS && window.BEL_ASSETS.emblem) ? window.BEL_ASSETS.emblem : 'image.asp?file=emblem';

            this.imgFull = new Image();
            this.imgFull.onload = onImgLoad;
            this.imgFull.src = (window.BEL_ASSETS && window.BEL_ASSETS.fullLogo) ? window.BEL_ASSETS.fullLogo : 'image.asp?file=full';

            if (this.imgEmblem.complete && this.imgFull.complete) {
                this.imagesReady = true;
            }
        },

        resize() {
            if (!this.canvas) return;
            const rect = this.canvas.getBoundingClientRect();
            this.width = rect.width || 500;
            this.height = rect.height || 380;
            this.dpr = Math.min(window.devicePixelRatio || 1, 2);

            this.canvas.width = this.width * this.dpr;
            this.canvas.height = this.height * this.dpr;
            this.ctx.scale(this.dpr, this.dpr);
        },

        updateStatus(statusText, counterText) {
            if (this.statusEl && statusText) this.statusEl.textContent = statusText;
            if (this.counterEl && counterText) this.counterEl.textContent = counterText;
        },

        resetAndPlay() {
            this.phase = 'FALLING';
            this.phaseStartTime = performance.now();
            this.shockwaveRadius = 0;
            this.shockwaveAlpha = 0;
            this.particles = [];
            this.updateStatus("Books Cascading...", "18 Volumes");

            const emblemCenterY = this.height / 2 - 8;
            const emblemW = Math.min(210, this.width * 0.44);

            // Three horizontal slices of the BEL speed-lined 'B' emblem
            const bandHeights = [emblemCenterY - emblemW * 0.28, emblemCenterY, emblemCenterY + emblemW * 0.28];
            const bandWidths = [emblemW * 0.92, emblemW * 0.84, emblemW * 0.88];

            this.books = this.catalog.map((item, idx) => {
                const bandIdx = idx % 3;
                const slotInBand = Math.floor(idx / 3);
                const totalInBand = 6;
                const bandCenterX = this.width / 2;
                const bandW = bandWidths[bandIdx];
                const slotWidth = bandW / totalInBand;
                const targetX = (bandCenterX - bandW / 2) + (slotInBand + 0.5) * slotWidth;
                const targetY = bandHeights[bandIdx];

                const startX = this.width * 0.12 + Math.random() * (this.width * 0.76);
                const startY = -40 - (idx * 26) - Math.random() * 60;

                return {
                    title: item.title,
                    bg: item.bg,
                    spine: item.spine,
                    ribbon: item.ribbon,
                    w: item.w,
                    h: item.h,
                    x: startX,
                    y: startY,
                    vx: (Math.random() - 0.5) * 1.2,
                    vy: 1.8 + Math.random() * 1.6,
                    angle: (Math.random() - 0.5) * 0.35,
                    vAngle: (Math.random() - 0.5) * 0.015,
                    origX: startX,
                    origY: startY,
                    origAngle: 0,
                    targetX: targetX,
                    targetY: targetY,
                    targetW: slotWidth + 4,
                    targetH: 26,
                    bandIdx: bandIdx,
                    ribbonSide: idx % 2 === 0 ? 1 : -1,
                    ribbonPhase: Math.random() * Math.PI * 2
                };
            });
        },

        dropExtraBook() {
            const item = this.catalog[Math.floor(Math.random() * this.catalog.length)];
            const book = {
                title: item.title,
                bg: item.bg,
                spine: item.spine,
                ribbon: item.ribbon,
                w: item.w,
                h: item.h,
                x: 60 + Math.random() * (this.width - 120),
                y: -50,
                vx: (Math.random() - 0.5) * 2,
                vy: 2.5 + Math.random() * 2,
                angle: (Math.random() - 0.5) * 0.4,
                vAngle: (Math.random() - 0.5) * 0.02,
                origX: 0,
                origY: 0,
                origAngle: 0,
                targetX: 0,
                targetY: 0,
                targetW: item.w,
                targetH: item.h,
                bandIdx: 0,
                ribbonSide: 1,
                ribbonPhase: Math.random() * Math.PI,
                isExtra: true
            };
            this.books.push(book);
        },

        animate() {
            this.update();
            this.render();
            this.animFrameId = requestAnimationFrame(() => this.animate());
        },

        update() {
            const now = performance.now();
            const elapsed = now - this.phaseStartTime;

            // Phase State Machine
            if (this.phase === 'FALLING') {
                // Free fall with gentle gravity
                this.books.forEach(b => {
                    b.vy += 0.22;
                    b.y += b.vy;
                    b.x += b.vx;
                    b.angle += b.vAngle;

                    // Floor bounce
                    const floorY = this.height - 35;
                    if (b.y > floorY) {
                        b.y = floorY;
                        b.vy = -b.vy * 0.25;
                        b.vx *= 0.85;
                        b.vAngle *= 0.5;
                    }
                });

                if (elapsed > 2000) {
                    this.phase = 'CONVERGING';
                    this.phaseStartTime = now;
                    this.updateStatus("⚡ Assembling BEL Logo...", "Aligning Spines");

                    // Snapshot positions at start of convergence
                    this.books.forEach(b => {
                        b.origX = b.x;
                        b.origY = b.y;
                        b.origAngle = b.angle;
                    });
                }
            } else if (this.phase === 'CONVERGING') {
                const convergeDuration = 1800;
                const p = Math.min(1, elapsed / convergeDuration);
                // Cubic ease in-out
                const ease = p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;

                this.books.forEach(b => {
                    if (b.isExtra) {
                        b.vy += 0.25;
                        b.y += b.vy;
                        return;
                    }
                    b.x = b.origX + (b.targetX - b.origX) * ease;
                    b.y = b.origY + (b.targetY - b.origY) * ease;
                    b.angle = b.origAngle * (1 - ease);
                });

                // Spawn cyan magnetic particles
                if (Math.random() < 0.45) {
                    this.particles.push({
                        x: this.width / 2 + (Math.random() - 0.5) * 220,
                        y: this.height / 2 + (Math.random() - 0.5) * 160,
                        vx: (Math.random() - 0.5) * 1.5,
                        vy: (Math.random() - 0.5) * 1.5,
                        alpha: 1,
                        size: 2 + Math.random() * 3,
                        color: "#00a2e8"
                    });
                }

                if (elapsed >= convergeDuration) {
                    this.phase = 'EMBLEM_FORMED';
                    this.phaseStartTime = now;
                    this.shockwaveRadius = 10;
                    this.shockwaveAlpha = 1.0;
                    this.updateStatus("✦ BEL Emblem Formed", "Emblem Complete");
                }
            } else if (this.phase === 'EMBLEM_FORMED') {
                // Expanding shockwave pulse
                if (this.shockwaveAlpha > 0) {
                    this.shockwaveRadius += 4.5;
                    this.shockwaveAlpha = Math.max(0, this.shockwaveAlpha - 0.025);
                }

                if (elapsed > 1600) {
                    this.phase = 'ELABORATING';
                    this.phaseStartTime = now;
                    this.updateStatus("✦ Elaborating Full Logo...", "Revealing Typography");
                }
            } else if (this.phase === 'ELABORATING') {
                const elaborateDuration = 1900;
                if (elapsed >= elaborateDuration) {
                    this.phase = 'COMPLETED';
                    this.phaseStartTime = now;
                    this.updateStatus("✦ Bharat Electronics Limited", "Knowledge OS 2.0");
                }
            }

            // Update particles
            for (let i = this.particles.length - 1; i >= 0; i--) {
                const p = this.particles[i];
                p.x += p.vx;
                p.y += p.vy;
                p.alpha -= 0.03;
                if (p.alpha <= 0) {
                    this.particles.splice(i, 1);
                }
            }
        },

        render() {
            const ctx = this.ctx;
            const w = this.width;
            const h = this.height;
            const now = performance.now();

            // 1. Clean Pure White Canvas Background - Absolutely Zero Graph Lines or Dots
            ctx.clearRect(0, 0, w, h);
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, w, h);

            const centerY = h / 2;

            // 2. Render Phase: FALLING or CONVERGING (Books in motion)
            if (this.phase === 'FALLING' || this.phase === 'CONVERGING') {
                // Render Each Book
                this.books.forEach(b => {
                    ctx.save();
                    ctx.translate(b.x, b.y);
                    ctx.rotate(b.angle);

                    const halfW = b.w / 2;
                    const halfH = b.h / 2;

                    // Soft Drop Shadow
                    ctx.shadowColor = 'rgba(0, 40, 90, 0.10)';
                    ctx.shadowBlur = 8;
                    ctx.shadowOffsetY = 4;

                    // Book Spine Body
                    const grad = ctx.createLinearGradient(-halfW, 0, halfW, 0);
                    if (this.phase === 'CONVERGING') {
                        const elapsed = now - this.phaseStartTime;
                        const p = Math.min(1, elapsed / 1800);
                        grad.addColorStop(0, '#00a2e8');
                        grad.addColorStop(1, '#0284c7');
                    } else {
                        grad.addColorStop(0, b.bg[0]);
                        grad.addColorStop(1, b.bg[1]);
                    }
                    ctx.fillStyle = grad;
                    ctx.roundRect(-halfW, -halfH, b.w, b.h, 4);
                    ctx.fill();

                    // Spine Edge Accent Line
                    ctx.shadowColor = 'transparent';
                    ctx.fillStyle = b.spine;
                    ctx.fillRect(-halfW + 4, -halfH, 3, b.h);
                    ctx.fillRect(halfW - 7, -halfH, 3, b.h);

                    // Spine Title Text (Kannada & English)
                    if (b.w > 80) {
                        ctx.fillStyle = '#ffffff';
                        ctx.font = 'bold 10.5px "Plus Jakarta Sans", "Noto Sans Kannada", sans-serif';
                        ctx.textAlign = 'center';
                        ctx.textBaseline = 'middle';
                        ctx.fillText(b.title, 0, 0, b.w - 24);
                    }

                    // Dangling Silk Ribbon Bookmark
                    ctx.beginPath();
                    const ribX = b.ribbonSide * (halfW - 20);
                    ctx.moveTo(ribX, halfH);
                    ctx.lineTo(ribX + 2, halfH + 16);
                    ctx.lineTo(ribX + 6, halfH + 12);
                    ctx.lineTo(ribX + 10, halfH + 16);
                    ctx.lineTo(ribX + 12, halfH);
                    ctx.closePath();
                    ctx.fillStyle = b.ribbon;
                    ctx.fill();

                    ctx.restore();
                });
            }

            // 3. Render Shockwave Pulse on Emblem Formed
            if (this.shockwaveAlpha > 0) {
                ctx.save();
                ctx.strokeStyle = `rgba(0, 162, 232, ${this.shockwaveAlpha})`;
                ctx.lineWidth = 2.5;
                ctx.beginPath();
                ctx.arc(w / 2, centerY, this.shockwaveRadius, 0, Math.PI * 2);
                ctx.stroke();
                ctx.restore();
            }

            // 4. Render Phase: EMBLEM_FORMED (BEL Emblem centered on pure white)
            if (this.phase === 'EMBLEM_FORMED') {
                const emblemW = Math.min(280, w * 0.55);
                const emblemH = emblemW * (230 / 385);
                const emX = (w - emblemW) / 2;
                const emY = (h - emblemH) / 2;

                if (this.imgEmblem && this.imgEmblem.complete && this.imgEmblem.naturalWidth > 0) {
                    ctx.drawImage(this.imgEmblem, emX, emY, emblemW, emblemH);
                } else {
                    this.drawVectorEmblem(ctx, w / 2, centerY, emblemW);
                }
            }

            // 5. Render Phase: ELABORATING (Transitioning from Emblem to Full Logo)
            if (this.phase === 'ELABORATING') {
                const elapsed = now - this.phaseStartTime;
                const duration = 1900;
                const p = Math.min(1, elapsed / duration);
                const ease = p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;

                // Full Logo target bounds (aspect ratio 380:120)
                const fullW = Math.min(460, w * 0.88);
                const fullH = fullW * (120 / 380);
                const fullX = (w - fullW) / 2;
                const fullY = (h - fullH) / 2;

                if (this.imgFull && this.imgFull.complete && this.imgFull.naturalWidth > 0) {
                    // Wipe reveal from left to right
                    const revealWidth = fullW * ease;

                    ctx.save();
                    ctx.beginPath();
                    ctx.rect(fullX, fullY, revealWidth, fullH);
                    ctx.clip();
                    ctx.drawImage(this.imgFull, fullX, fullY, fullW, fullH);
                    ctx.restore();

                    // Soft Cyan Sweep Beam
                    const beamX = fullX + revealWidth;
                    ctx.save();
                    const beamGrad = ctx.createLinearGradient(beamX - 10, 0, beamX + 10, 0);
                    beamGrad.addColorStop(0, 'rgba(0, 162, 232, 0)');
                    beamGrad.addColorStop(0.5, 'rgba(0, 162, 232, 0.8)');
                    beamGrad.addColorStop(1, 'rgba(0, 162, 232, 0)');
                    ctx.fillStyle = beamGrad;
                    ctx.fillRect(beamX - 10, fullY - 10, 20, fullH + 20);

                    // Subtle glowing point
                    ctx.fillStyle = '#ffffff';
                    ctx.shadowColor = '#00a2e8';
                    ctx.shadowBlur = 10;
                    ctx.beginPath();
                    ctx.arc(beamX, fullY + fullH / 2, 3.5, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.restore();
                } else {
                    this.drawVectorEmblem(ctx, w * 0.35, centerY, 220);
                    this.drawVectorTypography(ctx, w * 0.55, centerY, ease);
                }
            }

            // 6. Render Phase: COMPLETED (Full Logo cleanly showcased)
            if (this.phase === 'COMPLETED') {
                const fullW = Math.min(460, w * 0.88);
                const fullH = fullW * (120 / 380);
                const fullX = (w - fullW) / 2;
                const fullY = (h - fullH) / 2;

                if (this.imgFull && this.imgFull.complete && this.imgFull.naturalWidth > 0) {
                    ctx.drawImage(this.imgFull, fullX, fullY, fullW, fullH);

                    // Periodic ambient light sheen sweep
                    const cycle = (now % 4200) / 1200;
                    if (cycle <= 1.0) {
                        const sheenX = fullX + fullW * cycle;
                        ctx.save();
                        ctx.beginPath();
                        ctx.rect(fullX, fullY, fullW, fullH);
                        ctx.clip();

                        const sheenGrad = ctx.createLinearGradient(sheenX - 35, fullY, sheenX + 35, fullY + fullH);
                        sheenGrad.addColorStop(0, 'rgba(255, 255, 255, 0)');
                        sheenGrad.addColorStop(0.5, 'rgba(255, 255, 255, 0.45)');
                        sheenGrad.addColorStop(1, 'rgba(255, 255, 255, 0)');
                        ctx.fillStyle = sheenGrad;
                        ctx.fillRect(sheenX - 35, fullY, 70, fullH);
                        ctx.restore();
                    }
                } else {
                    this.drawVectorEmblem(ctx, w * 0.35, centerY, 220);
                    this.drawVectorTypography(ctx, w * 0.55, centerY, 1.0);
                }
            }

            // 7. Render Energy Sparks
            this.particles.forEach(p => {
                ctx.save();
                ctx.globalAlpha = Math.max(0, p.alpha);
                ctx.fillStyle = p.color;
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            });
        },

        drawVectorEmblem(ctx, cx, cy, size) {
            ctx.save();
            ctx.fillStyle = '#00a2e8';
            const h = size * 0.22;
            const w = size * 0.85;
            // 3 aerodynamic bands
            ctx.roundRect(cx - w / 2, cy - size * 0.3, w, h, [4, 18, 18, 4]);
            ctx.fill();
            ctx.roundRect(cx - w / 2 + 10, cy - h / 2, w * 0.88, h * 0.9, [4, 16, 16, 4]);
            ctx.fill();
            ctx.roundRect(cx - w / 2 - 10, cy + size * 0.3 - h, w * 0.96, h, [4, 18, 18, 4]);
            ctx.fill();
            ctx.restore();
        },

        drawVectorTypography(ctx, tx, ty, alpha) {
            ctx.save();
            ctx.globalAlpha = Math.max(0, Math.min(1, alpha));
            ctx.fillStyle = '#0f172a';
            ctx.font = 'bold 20px "Plus Jakarta Sans", "Noto Sans Devanagari", sans-serif';
            ctx.textAlign = 'left';
            ctx.fillText("भारत इलेक्ट्रॉनिक्स", tx, ty - 8);

            ctx.strokeStyle = '#00a2e8';
            ctx.lineWidth = 2.5;
            ctx.beginPath();
            ctx.moveTo(tx, ty + 2);
            ctx.lineTo(tx + 180, ty + 2);
            ctx.stroke();

            ctx.font = 'italic 800 15px "Plus Jakarta Sans", sans-serif';
            ctx.fillText("BHARAT ELECTRONICS", tx, ty + 24);
            ctx.restore();
        }
    };


    // ====================================================================
    // INITIALIZATION
    // ====================================================================
    // ====================================================================
    // 15. PAGE TRANSITION VEIL ENGINE
    // ====================================================================
    const PageTransition = {
        veil: null,
        FADE_IN_MS: 220,   // page-arrive fade (veil disappears)
        FADE_OUT_MS: 180,  // page-leave fade  (veil appears)

        init() {
            this.veil = document.getElementById('page-veil');
            if (!this.veil) return;

            // Arrive: immediately fade the veil out
            this._fadeIn();

            // Leave: intercept every same-origin <a> click
            document.addEventListener('click', (e) => {
                const link = e.target.closest('a[href]');
                if (!link) return;

                const href = link.getAttribute('href');
                if (!href) return;

                // Skip: external, hash-only, javascript:, target=_blank
                if (link.target === '_blank') return;
                if (href.startsWith('#')) return;
                if (href.startsWith('javascript')) return;
                if (href.startsWith('http') && !href.startsWith(location.origin)) return;

                // Skip: form submit buttons that happen to be links
                if (link.closest('form')) return;

                e.preventDefault();
                const dest = href;

                this._fadeOut(() => {
                    window.location.href = dest;
                });
            });

            // Also catch form submits — fade out before POST/GET only if submission is valid and not cancelled
            document.addEventListener('submit', (e) => {
                if (e.defaultPrevented) return;
                if (e.target && typeof e.target.checkValidity === 'function' && !e.target.checkValidity()) {
                    return;
                }
                this._fadeOut();
                // Safety watchdog: restore view if submission is halted or doesn't navigate
                setTimeout(() => {
                    this._fadeIn();
                }, 3000);
            });

            // On browser forward/back or page show, ensure veil is dismissed
            window.addEventListener('pageshow', () => {
                this._fadeIn();
            });
        },

        _fadeIn() {
            if (!this.veil) return;
            // Force a reflow so the transition fires even if added in the same frame
            this.veil.getBoundingClientRect();
            this.veil.classList.remove('veil-out');
            this.veil.classList.add('veil-hidden');
        },

        _fadeOut(callback) {
            if (!this.veil) {
                if (callback) callback();
                return;
            }
            this.veil.classList.remove('veil-hidden');
            this.veil.classList.add('veil-out');
            if (callback) {
                setTimeout(callback, this.FADE_OUT_MS + 20);
            }
        }
    };

    // ====================================================================
    // INITIALIZATION
    // ====================================================================
    function initAllEngines() {
        PageTransition.init();
        ThemeManager.init();
        SpotlightEngine.init();
        TiltEngine.init();
        CommandPalette.init();
        SlideOverDrawer.init();
        SparklineEngine.init();
        RadialGaugeEngine.init();
        KeyboardEngine.init();
        ViewToggle.init();
        MultiFacetFilter.init();
        LiveTableFilter.init();
        TableSorter.init();
        DemoLogin.init();
        MobileSidebar.init();
        FallingBooksEngine.init();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAllEngines);
    } else {
        initAllEngines();
    }

    // Expose Global API
    window.FallingBooksEngine = FallingBooksEngine;
    window.BelUI = {
        openBookDrawer: (book) => SlideOverDrawer.open(book),
        closeDrawer: () => SlideOverDrawer.close(),
        openCommandPalette: () => CommandPalette.open(),
        toggleTheme: () => ThemeManager.toggleTheme(),
        showToast: (msg, type) => ToastManager.show(msg, type),
        replayLogo: () => FallingBooksEngine.resetAndPlay()
    };
})();
