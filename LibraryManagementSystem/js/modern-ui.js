/**
 * BEL Library Management System - Vanilla JavaScript Toolkit
 * Zero external dependencies. Modern ES6+ component architecture.
 */

(function () {
    'use strict';

    // ====================================================================
    // 1. Theme Manager (Dark / Light Mode)
    // ====================================================================
    const ThemeManager = {
        STORAGE_KEY: 'bel_theme',

        init() {
            const savedTheme = localStorage.getItem(this.STORAGE_KEY);
            const systemPrefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
            const activeTheme = savedTheme || (systemPrefersDark ? 'dark' : 'light');

            this.applyTheme(activeTheme);

            const toggleBtn = document.getElementById('themeToggleBtn');
            if (toggleBtn) {
                toggleBtn.addEventListener('click', () => this.toggle());
            }

            // Sync with mobile drawer toggle button as well
            const mobileToggleBtn = document.getElementById('mobileThemeToggleBtn');
            if (mobileToggleBtn) {
                mobileToggleBtn.addEventListener('click', () => this.toggle());
            }
        },

        applyTheme(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem(this.STORAGE_KEY, theme);
            this.updateIcons(theme);
        },

        toggle() {
            const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
            const nextTheme = currentTheme === 'dark' ? 'light' : 'dark';
            this.applyTheme(nextTheme);
            if (window.Toast) {
                window.Toast.show(`Switched to ${nextTheme.charAt(0).toUpperCase() + nextTheme.slice(1)} Mode`, 'info', 2000);
            }
        },

        updateIcons(theme) {
            const sunIcon = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>`;
            const moonIcon = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>`;

            const btns = [document.getElementById('themeToggleBtn'), document.getElementById('mobileThemeToggleBtn')];
            btns.forEach(btn => {
                if (btn) {
                    btn.innerHTML = theme === 'dark' ? sunIcon : moonIcon;
                    btn.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'Light' : 'Dark'} Mode`);
                }
            });
        }
    };

    // ====================================================================
    // 2. Floating Toast Notification Engine
    // ====================================================================
    const ToastManager = {
        container: null,

        init() {
            let existing = document.getElementById('toastContainer');
            if (!existing) {
                existing = document.createElement('div');
                existing.id = 'toastContainer';
                existing.className = 'toast-container';
                document.body.appendChild(existing);
            }
            this.container = existing;

            // Automatically check for classic ASP alerts on page load and enhance them
            const aspAlerts = document.querySelectorAll('.alert');
            aspAlerts.forEach(alert => {
                let type = 'info';
                if (alert.classList.contains('alert-danger')) type = 'error';
                else if (alert.classList.contains('alert-success')) type = 'success';
                else if (alert.classList.contains('alert-warning')) type = 'warning';

                const text = alert.textContent.trim();
                if (text) {
                    this.show(text, type, 4500);
                }
            });
        },

        show(message, type = 'info', duration = 3500) {
            if (!this.container) this.init();

            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;

            let iconSvg = '';
            if (type === 'success') {
                iconSvg = `<svg class="toast-icon" style="color:var(--success)" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`;
            } else if (type === 'error') {
                iconSvg = `<svg class="toast-icon" style="color:var(--danger)" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`;
            } else {
                iconSvg = `<svg class="toast-icon" style="color:var(--info)" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>`;
            }

            toast.innerHTML = `
                ${iconSvg}
                <span>${message}</span>
                <button class="toast-close" aria-label="Close">&times;</button>
            `;

            toast.querySelector('.toast-close').addEventListener('click', () => {
                toast.classList.remove('show');
                setTimeout(() => toast.remove(), 300);
            });

            this.container.appendChild(toast);

            // Animate in
            requestAnimationFrame(() => {
                toast.classList.add('show');
            });

            // Auto dismiss
            setTimeout(() => {
                if (toast.parentElement) {
                    toast.classList.remove('show');
                    setTimeout(() => toast.remove(), 300);
                }
            }, duration);
        }
    };

    window.Toast = ToastManager;

    // ====================================================================
    // 3. Live Instant Table Search & Filtering (Zero Server Hit)
    // ====================================================================
    const LiveTableFilter = {
        init() {
            const searchInputs = document.querySelectorAll('[data-live-filter]');
            searchInputs.forEach(input => {
                const targetTableId = input.getAttribute('data-live-filter');
                const table = document.getElementById(targetTableId);
                if (!table) return;

                const tbody = table.querySelector('tbody');
                if (!tbody) return;

                input.addEventListener('input', (e) => {
                    const query = e.target.value.toLowerCase().trim();
                    const rows = tbody.querySelectorAll('tr:not(.no-filter-match)');
                    let matchCount = 0;

                    rows.forEach(row => {
                        const text = row.textContent.toLowerCase();
                        if (query === '' || text.includes(query)) {
                            row.style.display = '';
                            matchCount++;
                        } else {
                            row.style.display = 'none';
                        }
                    });

                    // Handle zero matches row
                    let emptyRow = tbody.querySelector('.no-filter-match');
                    if (matchCount === 0 && rows.length > 0) {
                        if (!emptyRow) {
                            emptyRow = document.createElement('tr');
                            emptyRow.className = 'no-filter-match';
                            const colCount = table.querySelectorAll('thead th').length || 6;
                            emptyRow.innerHTML = `<td colspan="${colCount}" style="text-align:center; padding: 24px; color: var(--text-muted);">No records found matching "<strong>${e.target.value}</strong>"</td>`;
                            tbody.appendChild(emptyRow);
                        } else {
                            emptyRow.style.display = '';
                            emptyRow.querySelector('strong').textContent = e.target.value;
                        }
                    } else if (emptyRow) {
                        emptyRow.style.display = 'none';
                    }

                    // Also filter cards if in Grid View
                    const gridContainer = document.getElementById('booksGridContainer');
                    if (gridContainer) {
                        const cards = gridContainer.querySelectorAll('.book-card');
                        cards.forEach(card => {
                            const text = card.textContent.toLowerCase();
                            card.style.display = (query === '' || text.includes(query)) ? '' : 'none';
                        });
                    }
                });
            });
        }
    };

    // ====================================================================
    // 4. Client-Side Table Column Sorter
    // ====================================================================
    const TableSorter = {
        init() {
            const sortableHeaders = document.querySelectorAll('th.sortable');
            sortableHeaders.forEach(th => {
                th.addEventListener('click', () => {
                    const table = th.closest('table');
                    const tbody = table.querySelector('tbody');
                    const colIndex = Array.from(th.parentNode.children).indexOf(th);
                    const isAsc = !th.classList.contains('asc');

                    // Reset other headers
                    th.parentNode.querySelectorAll('th').forEach(h => h.classList.remove('asc', 'desc'));
                    th.classList.add(isAsc ? 'asc' : 'desc');

                    const rows = Array.from(tbody.querySelectorAll('tr:not(.no-filter-match)'));
                    rows.sort((a, b) => {
                        const valA = a.children[colIndex] ? a.children[colIndex].innerText.trim() : '';
                        const valB = b.children[colIndex] ? b.children[colIndex].innerText.trim() : '';

                        const numA = parseFloat(valA.replace(/[^0-9.-]+/g, ''));
                        const numB = parseFloat(valB.replace(/[^0-9.-]+/g, ''));

                        if (!isNaN(numA) && !isNaN(numB)) {
                            return isAsc ? numA - numB : numB - numA;
                        }
                        return isAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
                    });

                    rows.forEach(r => tbody.appendChild(r));
                });
            });
        }
    };

    // ====================================================================
    // 5. Grid View vs. Table View Toggle (Books Catalog)
    // ====================================================================
    const ViewToggle = {
        STORAGE_KEY: 'bel_books_view',

        init() {
            const btnTable = document.getElementById('btnViewTable');
            const btnGrid = document.getElementById('btnViewGrid');
            const tableView = document.getElementById('booksTableView');
            const gridView = document.getElementById('booksGridView');

            if (!btnTable || !btnGrid || !tableView || !gridView) return;

            const savedView = localStorage.getItem(this.STORAGE_KEY) || 'table';
            this.setView(savedView);

            btnTable.addEventListener('click', () => this.setView('table'));
            btnGrid.addEventListener('click', () => this.setView('grid'));
        },

        setView(mode) {
            const btnTable = document.getElementById('btnViewTable');
            const btnGrid = document.getElementById('btnViewGrid');
            const tableView = document.getElementById('booksTableView');
            const gridView = document.getElementById('booksGridView');

            if (!btnTable || !btnGrid || !tableView || !gridView) return;

            if (mode === 'grid') {
                tableView.style.display = 'none';
                gridView.style.display = 'grid';
                btnGrid.classList.add('active');
                btnTable.classList.remove('active');
            } else {
                gridView.style.display = 'none';
                tableView.style.display = '';
                btnTable.classList.add('active');
                btnGrid.classList.remove('active');
            }
            localStorage.setItem(this.STORAGE_KEY, mode);
        }
    };

    // ====================================================================
    // 6. Mobile Off-Canvas Navigation Drawer
    // ====================================================================
    const MobileNav = {
        init() {
            const toggleBtn = document.getElementById('mobileNavToggle');
            const drawer = document.getElementById('mobileDrawer');
            const backdrop = document.getElementById('mobileDrawerBackdrop');
            const closeBtn = document.getElementById('closeMobileDrawer');

            if (!toggleBtn || !drawer || !backdrop) return;

            const open = () => {
                drawer.classList.add('open');
                backdrop.classList.add('open');
                document.body.style.overflow = 'hidden';
            };

            const close = () => {
                drawer.classList.remove('open');
                backdrop.classList.remove('open');
                document.body.style.overflow = '';
            };

            toggleBtn.addEventListener('click', open);
            if (closeBtn) closeBtn.addEventListener('click', close);
            backdrop.addEventListener('click', close);
        }
    };

    // ====================================================================
    // 7. Demo Quick Login Credentials Loader
    // ====================================================================
    const DemoLogin = {
        init() {
            const emailInput = document.getElementById('loginEmail');
            const passInput = document.getElementById('loginPassword');
            const pills = document.querySelectorAll('[data-demo-role]');

            if (!emailInput || !passInput || pills.length === 0) return;

            const creds = {
                admin: { email: 'admin@bel.com', pass: 'Password123!' },
                librarian: { email: 'librarian@bel.com', pass: 'Password123!' },
                member: { email: 'john.doe@bel.com', pass: 'Password123!' }
            };

            pills.forEach(pill => {
                pill.addEventListener('click', () => {
                    const role = pill.getAttribute('data-demo-role');
                    if (creds[role]) {
                        emailInput.value = creds[role].email;
                        passInput.value = creds[role].pass;
                        emailInput.focus();
                        if (window.Toast) {
                            window.Toast.show(`Loaded demo credentials for ${role.toUpperCase()}`, 'info', 2000);
                        }
                    }
                });
            });

            // Password reveal toggle
            const eyeBtn = document.getElementById('togglePasswordEye');
            if (eyeBtn) {
                eyeBtn.addEventListener('click', () => {
                    const isPass = passInput.getAttribute('type') === 'password';
                    passInput.setAttribute('type', isPass ? 'text' : 'password');
                    eyeBtn.style.color = isPass ? 'var(--brand-primary)' : 'var(--text-muted)';
                });
            }
        }
    };

    // ====================================================================
    // 8. Lightweight Pure SVG Dashboard Micro-Charts
    // ====================================================================
    const SvgCharts = {
        init() {
            const chartContainers = document.querySelectorAll('[data-svg-donut]');
            chartContainers.forEach(container => {
                const total = parseInt(container.getAttribute('data-total') || '100', 10);
                const active = parseInt(container.getAttribute('data-active') || '0', 10);
                const available = Math.max(0, total - active);

                const pctActive = total > 0 ? Math.round((active / total) * 100) : 0;
                const circumference = 2 * Math.PI * 40; // r=40
                const activeOffset = circumference - (circumference * pctActive) / 100;

                container.innerHTML = `
                    <div style="display:flex; align-items:center; gap: 20px;">
                        <svg width="100" height="100" viewBox="0 0 100 100" style="transform: rotate(-90deg);">
                            <circle cx="50" cy="50" r="40" fill="transparent" stroke="var(--bg-surface-subtle)" stroke-width="12" />
                            <circle cx="50" cy="50" r="40" fill="transparent" stroke="var(--brand-primary)" stroke-width="12"
                                stroke-dasharray="${circumference}" stroke-dashoffset="${activeOffset}" stroke-linecap="round"
                                style="transition: stroke-dashoffset 1s ease-out;" />
                        </svg>
                        <div style="display:flex; flex-direction:column; gap:6px;">
                            <div style="font-size:12px; color:var(--text-muted);"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--brand-primary);margin-right:6px;"></span>Active Loans: <strong>${active} (${pctActive}%)</strong></div>
                            <div style="font-size:12px; color:var(--text-muted);"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--bg-surface-subtle);margin-right:6px;"></span>Available In Shelves: <strong>${available}</strong></div>
                        </div>
                    </div>
                `;
            });
        }
    };

    // ====================================================================
    // Initialize on DOM Ready
    // ====================================================================
    document.addEventListener('DOMContentLoaded', () => {
        ThemeManager.init();
        ToastManager.init();
        LiveTableFilter.init();
        TableSorter.init();
        ViewToggle.init();
        MobileNav.init();
        DemoLogin.init();
        SvgCharts.init();
    });

})();
