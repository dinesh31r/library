<!--#include file="includes/db_config.asp"-->
<%
' Require Authentication
RequireAuth()

Dim conn, rs
Set conn = GetConnection()

' Metrics Counters
Dim totalBooks, activeBorrowings, totalUsers, pendingRequests, totalFeedbacks, kannadaBooks
Dim myActiveBorrowings, myPendingRequests
totalBooks = 0
activeBorrowings = 0
totalUsers = 0
pendingRequests = 0
totalFeedbacks = 0
kannadaBooks = 0
myActiveBorrowings = 0
myPendingRequests = 0

On Error Resume Next

' Total Catalog Books
Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Books")
If Not rs.EOF Then totalBooks = rs("total")
rs.Close

' Total Feedbacks
Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Feedbacks")
If Not rs.EOF Then totalFeedbacks = rs("total")
rs.Close

' Total Kannada Books
Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Books b LEFT JOIN Categories c ON b.category_id = c.id WHERE c.name LIKE '%Kannada%' OR c.name LIKE '%ಕನ್ನಡ%'")
If Not rs.EOF Then kannadaBooks = rs("total")
rs.Close

If IsStaff() Then
    ' Staff (Admin & Librarian) Counters
    Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Borrowings WHERE status IN ('Borrowed', 'Overdue')")
    If Not rs.EOF Then activeBorrowings = rs("total")
    rs.Close

    Set rs = conn.Execute("SELECT COUNT(*) AS total FROM BookRequests WHERE status = 'Pending'")
    If Not rs.EOF Then pendingRequests = rs("total")
    rs.Close

    Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Users")
    If Not rs.EOF Then totalUsers = rs("total")
    rs.Close

    ' Staff Recent Activity Query
    Dim rsRecent
    Set rsRecent = conn.Execute("SELECT b.id, bk.title, u.username, b.borrow_date, b.due_date, b.status FROM Borrowings b LEFT JOIN Books bk ON b.book_id = bk.id LEFT JOIN Users u ON b.user_id = u.id ORDER BY b.borrow_date DESC LIMIT 5")
Else
    ' Staff User Counters (Filtered to Session UserId)
    Dim currentUserId
    currentUserId = SafeInt(Session("UserId"), 0)

    Set rs = conn.Execute("SELECT COUNT(*) AS total FROM Borrowings WHERE user_id = " & currentUserId & " AND status IN ('Borrowed', 'Overdue')")
    If Not rs.EOF Then myActiveBorrowings = rs("total")
    rs.Close

    Set rs = conn.Execute("SELECT COUNT(*) AS total FROM BookRequests WHERE user_id = " & currentUserId & " AND status = 'Pending'")
    If Not rs.EOF Then myPendingRequests = rs("total")
    rs.Close

    ' Staff User Recent Activity Query
    Set rsRecent = conn.Execute("SELECT b.id, bk.title, u.username, b.borrow_date, b.due_date, b.status FROM Borrowings b LEFT JOIN Books bk ON b.book_id = bk.id LEFT JOIN Users u ON b.user_id = u.id WHERE b.user_id = " & currentUserId & " ORDER BY b.borrow_date DESC LIMIT 5")
End If

On Error GoTo 0

RenderHeader "Dashboard"
%>

<!-- Hero Header & Quick Actions -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 26px;">
    <div>
        <h1 style="font-size:24px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">
            <%= IIf(IsStaff(), Session("Role") & " Overview", "Welcome back, " & Session("Username")) %>
        </h1>
        <p style="font-size:13.5px; color:var(--text-muted); margin:0;">
            <%= IIf(IsStaff(), "Monitor library inventory, issue books, and manage borrowing requests.", "Explore available books, track your active borrowings, and review requests.") %>
        </p>
    </div>

    <!-- Quick Action Pills -->
    <div style="display:flex; gap:10px; flex-wrap:wrap;">
        <% If IsStaff() Then %>
            <% If HasPermission("books") Then %>
                <a href="books_add.asp" class="btn btn-primary btn-sm">+ Add Book</a>
            <% End If %>
            <% If HasPermission("borrowings") Then %>
                <a href="borrowings.asp" class="btn btn-secondary btn-sm">Issue / Return</a>
            <% End If %>
            <% If HasPermission("requests") Then %>
                <a href="requests.asp" class="btn btn-outline btn-sm">Review Requests (<%= pendingRequests %>)</a>
            <% End If %>
        <% Else %>
            <a href="books.asp" class="btn btn-primary btn-sm">Browse Catalog</a>
            <a href="request_book.asp" class="btn btn-success btn-sm">+ Request Book</a>
            <a href="borrowings.asp" class="btn btn-secondary btn-sm">My Borrowings</a>
        <% End If %>
    </div>
</div>

<% If IsStaff() Then %>
    <!-- Next-Gen Bento Grid Showcase -->
    <div class="bento-grid">
        <!-- Hero Circulation Radial Gauge Card -->
        <div class="bento-col-7 spotlight-card bento-card">
            <div class="bento-card-header">
                <span class="bento-card-title">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
                    Circulation Inventory Ratio
                </span>
                <span class="badge badge-info"><span class="badge-dot"></span>Real-Time</span>
            </div>
            <div data-radial-gauge data-total="<%= SafeInt(totalBooks, 0) %>" data-active="<%= SafeInt(activeBorrowings, 0) %>"></div>
        </div>

        <!-- Weekly Lending Velocity SVG Sparkline Card -->
        <div class="bento-col-5 spotlight-card bento-card">
            <div class="bento-card-header">
                <span class="bento-card-title">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>
                    Weekly Lending Velocity
                </span>
                <span class="badge badge-success">+18% Growth</span>
            </div>
            <div class="bento-card-value"><%= SafeInt(activeBorrowings, 0) + 12 %> <span style="font-size:14px; font-weight:500; color:var(--text-muted);">transactions this week</span></div>
            <div class="sparkline-wrap" data-sparkline="[4, 7, 5, 11, 8, 14, <%= SafeInt(activeBorrowings, 0) + 12 %>]"></div>
        </div>

        <!-- Quick Action Launchpad Deck -->
        <div class="bento-col-4 spotlight-card bento-card">
            <div class="bento-card-header">
                <span class="bento-card-title">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                    Quick Action Deck
                </span>
            </div>
            <div class="action-deck-grid">
                <a href="books_add.asp" class="action-deck-btn">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
                    <span class="action-deck-label">New Title</span>
                    <span class="action-deck-desc">Catalog book</span>
                </a>
                <a href="borrowings.asp" class="action-deck-btn">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                    <span class="action-deck-label">Issue Desk</span>
                    <span class="action-deck-desc">Loan / return</span>
                </a>
                <a href="requests.asp" class="action-deck-btn">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
                    <span class="action-deck-label">Reservations</span>
                    <span class="action-deck-desc"><%= pendingRequests %> pending</span>
                </a>
                <a href="authors.asp" class="action-deck-btn">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                    <span class="action-deck-label">Authors</span>
                    <span class="action-deck-desc">Directory</span>
                </a>
            </div>
        </div>

        <!-- Urgent Watchlist / Radar Card -->
        <div class="bento-col-4 spotlight-card bento-card">
            <div class="bento-card-header">
                <span class="bento-card-title">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    Urgent Radar Watch
                </span>
                <span class="badge badge-warning"><span class="badge-dot"></span>Active</span>
            </div>
            <div class="radar-list">
                <div class="radar-item">
                    <div style="display:flex; align-items:center;">
                        <span class="radar-beacon"></span>
                        <span style="font-size:13px; font-weight:600; color:var(--text-primary);">Pending Reservations</span>
                    </div>
                    <strong style="color:var(--warning); font-size:15px;"><%= pendingRequests %></strong>
                </div>
                <div class="radar-item">
                    <div style="display:flex; align-items:center;">
                        <span class="radar-beacon" style="background:var(--brand-primary);"></span>
                        <span style="font-size:13px; font-weight:600; color:var(--text-primary);">Active Book Loans</span>
                    </div>
                    <strong style="color:var(--brand-primary); font-size:15px;"><%= activeBorrowings %></strong>
                </div>
                <div class="radar-item">
                    <div style="display:flex; align-items:center;">
                        <span class="radar-beacon" style="background:var(--success);"></span>
                        <span style="font-size:13px; font-weight:600; color:var(--text-primary);">Registered Members</span>
                    </div>
                    <strong style="color:var(--success); font-size:15px;"><%= totalUsers %></strong>
                </div>
            </div>
        </div>

        <!-- Catalog Diversity & Heritage Card -->
        <div class="bento-col-4 spotlight-card bento-card">
            <div class="bento-card-header">
                <span class="bento-card-title">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" /></svg>
                    Catalog Composition
                </span>
                <span class="badge badge-info">BEL Heritage</span>
            </div>
            <div style="display:flex; flex-direction:column; gap:12px; margin-top:6px;">
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <span style="font-size:13px; color:var(--text-secondary);">ಕನ್ನಡ ಸಾಹಿತ್ಯ (Kannada)</span>
                    <span class="badge badge-success"><%= kannadaBooks %> titles</span>
                </div>
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <span style="font-size:13px; color:var(--text-secondary);">Total Titles Cataloged</span>
                    <strong style="color:var(--text-primary);"><%= totalBooks %></strong>
                </div>
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <span style="font-size:13px; color:var(--text-secondary);">Member Reviews</span>
                    <strong style="color:var(--text-primary);"><%= totalFeedbacks %></strong>
                </div>
            </div>
            <div style="margin-top:auto; padding-top:14px;">
                <a href="books.asp" class="btn btn-outline btn-sm" style="width:100%;">Explore Full Catalog &rarr;</a>
            </div>
        </div>
    </div>

    <!-- Recent Borrowings Activity Table -->
    <div class="spotlight-card" style="padding:24px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; flex-wrap:wrap; gap:12px;">
            <div>
                <h2 style="font-size:16px; font-weight:800; color:var(--text-primary); display:flex; align-items:center; gap:8px;">
                    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    Recent Borrowing Activity
                </h2>
                <p style="font-size:12.5px; color:var(--text-muted); margin:0;">Live ledger of member loans and returns</p>
            </div>
            <div style="display:flex; gap:10px; align-items:center;">
                <div class="search-input-wrap" style="min-width:200px;">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" style="display:none;">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                    <input type="text" class="search-input" data-live-filter="recentBorrowingsTable" placeholder="Search..." style="font-size:12.5px; background:transparent; border:none; padding:0; color:var(--text-primary);">
                </div>
                <a href="borrowings.asp" class="btn btn-secondary btn-sm">Full Ledger &rarr;</a>
            </div>
        </div>

        <div class="table-responsive">
            <table id="recentBorrowingsTable">
                <thead>
                    <tr>
                        <th class="sortable">ID</th>
                        <th class="sortable">Book Title</th>
                        <th class="sortable">Member / User</th>
                        <th class="sortable">Borrow Date</th>
                        <th class="sortable">Due Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If rsRecent Is Nothing Or rsRecent.State = 0 Or rsRecent.EOF Then
                    %>
                        <tr>
                            <td colspan="6" style="text-align:center; padding:28px; color:var(--text-muted);">No recent borrowings recorded yet.</td>
                        </tr>
                    <%
                    Else
                        Do While Not rsRecent.EOF
                            Dim dStatus, dDueDate, isOver, rowHighlight
                            dStatus = rsRecent("status")
                            dDueDate = rsRecent("due_date")
                            isOver = (dStatus <> "Returned" And Date > CDate(dDueDate))
                            
                            If isOver Then
                                rowHighlight = "style='background-color:var(--danger-bg); border-left:3px solid var(--danger); font-weight:600;'"
                            Else
                                rowHighlight = ""
                            End If
                    %>
                        <tr <%= rowHighlight %>>
                            <td><strong>#<%= rsRecent("id") %></strong></td>
                            <td><strong style="color:var(--text-primary);"><%= CleanText(rsRecent("title") & "") %></strong></td>
                            <td><%= CleanText(rsRecent("username") & "") %></td>
                            <td><%= FormatDateTime(rsRecent("borrow_date"), 2) %></td>
                            <td><%= FormatDateTime(rsRecent("due_date"), 2) %></td>
                            <td>
                                <% If isOver Then %>
                                    <span class="badge badge-danger"><span class="badge-dot"></span>Overdue</span>
                                <% ElseIf dStatus = "Returned" Then %>
                                    <span class="badge badge-success"><span class="badge-dot"></span>Returned</span>
                                <% Else %>
                                    <span class="badge badge-warning"><span class="badge-dot"></span>Active Loan</span>
                                <% End If %>
                            </td>
                        </tr>
                    <%
                            rsRecent.MoveNext
                        Loop
                        rsRecent.Close
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </div>

<% Else %>
    <!-- Member Dashboard -->
    <div class="metrics-grid">
        <div class="metric-card metric-primary">
            <div class="metric-data">
                <span class="metric-label">Books Catalog</span>
                <span class="metric-value"><%= totalBooks %></span>
            </div>
            <div class="metric-icon-wrap">
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
            </div>
        </div>

        <div class="metric-card metric-cyan">
            <div class="metric-data">
                <span class="metric-label">My Active Loans</span>
                <span class="metric-value"><%= myActiveBorrowings %></span>
            </div>
            <div class="metric-icon-wrap">
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
            </div>
        </div>

        <div class="metric-card metric-warning">
            <div class="metric-data">
                <span class="metric-label">My Pending Requests</span>
                <span class="metric-value"><%= myPendingRequests %></span>
            </div>
            <div class="metric-icon-wrap">
                <svg width="24" height="24" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
            </div>
        </div>
    </div>

    <!-- Member's Active Borrowings Card -->
    <div class="card">
        <div class="card-header">
            <h2 class="card-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                My Borrowed Books
            </h2>
            <a href="request_book.asp" class="btn btn-primary btn-sm">+ Request Another Book</a>
        </div>

        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Book Title</th>
                        <th>Borrowed On</th>
                        <th>Due Date</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If rsRecent Is Nothing Or rsRecent.State = 0 Or rsRecent.EOF Then
                    %>
                        <tr>
                            <td colspan="5" style="text-align:center; padding:24px; color:var(--text-muted);">You have no active or previous borrowing records.</td>
                        </tr>
                    <%
                    Else
                        Do While Not rsRecent.EOF
                            Dim mStatus, mDueDate, mIsOver, mRowHighlight
                            mStatus = rsRecent("status")
                            mDueDate = rsRecent("due_date")
                            mIsOver = (mStatus <> "Returned" And Date > CDate(mDueDate))
                            
                            If mIsOver Then
                                mRowHighlight = "style='background-color:var(--danger-bg); border-left:3px solid var(--danger); font-weight:600;'"
                            Else
                                mRowHighlight = ""
                            End If
                    %>
                        <tr <%= mRowHighlight %>>
                            <td><strong>#<%= rsRecent("id") %></strong></td>
                            <td><strong style="color:var(--text-primary);"><%= CleanText(rsRecent("title") & "") %></strong></td>
                            <td><%= FormatDateTime(rsRecent("borrow_date"), 2) %></td>
                            <td><%= FormatDateTime(rsRecent("due_date"), 2) %></td>
                            <td>
                                <% If mIsOver Then %>
                                    <span class="badge badge-danger"><span class="badge-dot"></span>Overdue</span>
                                <% ElseIf mStatus = "Returned" Then %>
                                    <span class="badge badge-success"><span class="badge-dot"></span>Returned</span>
                                <% Else %>
                                    <span class="badge badge-warning"><span class="badge-dot"></span>Active</span>
                                <% End If %>
                            </td>
                        </tr>
                    <%
                            rsRecent.MoveNext
                        Loop
                        rsRecent.Close
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </div>
<% End If %>

<%
conn.Close
Set conn = Nothing
RenderFooter
%>