<!--#include file="includes/db_config.asp"-->
<%
RequireAuth()

Dim searchKeyword, conn, rs, sql
searchKeyword = Trim(Request.QueryString("q"))

Set conn = GetConnection()

sql = "SELECT b.id, b.title, b.isbn, b.publisher, b.price, b.copies_available, b.is_available, a.name AS author_name, c.name AS category_name, " & _
      "(SELECT COALESCE(AVG(rating), 0) FROM Feedbacks WHERE book_id = b.id) AS avg_rating, " & _
      "(SELECT COUNT(*) FROM Feedbacks WHERE book_id = b.id) AS review_count " & _
      "FROM Books b " & _
      "LEFT JOIN Authors a ON b.author_id = a.id " & _
      "LEFT JOIN Categories c ON b.category_id = c.id "

If searchKeyword <> "" Then
    sql = sql & "WHERE b.title LIKE " & SQLQuote("%" & searchKeyword & "%") & " OR b.isbn LIKE " & SQLQuote("%" & searchKeyword & "%") & " OR a.name LIKE " & SQLQuote("%" & searchKeyword & "%") & " "
End If

sql = sql & "ORDER BY b.id DESC"

On Error Resume Next
Set rs = conn.Execute(sql)

Dim booksData, hasBooks, totalRecords, r
hasBooks = False
totalRecords = -1

If Not (rs Is Nothing Or rs.State = 0) Then
    If Not rs.EOF Then
        booksData = rs.GetRows()
        hasBooks = True
        totalRecords = UBound(booksData, 2)
    End If
    rs.Close
End If
Set rs = Nothing
conn.Close
Set conn = Nothing
On Error GoTo 0

RenderHeader "Book Catalog & Inventory"
%>

<!-- Header & Fast Actions -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 20px;">
    <div>
        <h1 style="font-size:24px; font-weight:800; color:var(--text-primary); letter-spacing:-0.02em; margin-bottom:4px;">
            <%= IIf(IsStaff(), "Catalog & Inventory", "Library Catalog") %>
        </h1>
        <p style="font-size:13.5px; color:var(--text-muted); margin:0;">
            Browse titles, check live shelf availability, and inspect 3D details.
        </p>
    </div>

    <div style="display:flex; gap:10px; align-items:center;">
        <% If IsStaff() Then %>
            <a href="books_add.asp" class="btn btn-primary btn-sm">+ Catalog New Book</a>
        <% End If %>
    </div>
</div>

<!-- Multi-Facet Category Filter Pills Bar -->
<div class="filter-pills-bar">
    <button type="button" class="filter-pill active" data-filter="all">
        All Books <span class="filter-pill-count">(<%= totalRecords + 1 %>)</span>
    </button>
    <button type="button" class="filter-pill" data-filter="kannada">
        ಕನ್ನಡ ಸಾಹಿತ್ಯ (Kannada)
    </button>
    <button type="button" class="filter-pill" data-filter="available">
        In Stock Only
    </button>
</div>

<!-- Search & View Mode Switcher -->
<div class="spotlight-card" style="padding:14px 20px; margin-bottom:24px;">
    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:14px;">
        <div class="search-input-wrap" style="flex:1; max-width:440px;">
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" style="display:none;">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input type="text" class="search-input" data-live-filter="catalogMainContainer" placeholder="Search..." style="background:transparent; border:none; padding:0; font-size:13px; color:var(--text-primary);">
        </div>

        <!-- 3 View Mode Switcher -->
        <div style="display:flex; align-items:center; gap:6px;">
            <span style="font-size:12px; font-weight:700; color:var(--text-muted); text-transform:uppercase; margin-right:4px;">View:</span>
            <button type="button" id="btnViewGrid" class="btn btn-primary btn-sm" title="3D Card Grid View">
                <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" /></svg>
                Grid
            </button>
            <button type="button" id="btnViewTable" class="btn btn-secondary btn-sm" title="Data Table View">
                <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" /></svg>
                Table
            </button>
            <button type="button" id="btnViewCompact" class="btn btn-secondary btn-sm" title="Compact High-Density List">
                <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h7" /></svg>
                Compact
            </button>
        </div>
    </div>
</div>

<div id="catalogMainContainer">
    <!-- VIEW 1: 3D CARD GRID -->
    <div id="catalogGridView" class="books-grid">
        <%
        If Not hasBooks Then
        %>
            <div class="spotlight-card" style="grid-column: 1 / -1; text-align:center; padding:48px; color:var(--text-muted);">
                No books found matching criteria.
            </div>
        <%
        Else
            For r = 0 To totalRecords
                Dim bId, bTitle, bIsbn, bPub, bPrice, bCopies, bIsAvail, bAuthor, bCategory, bRating, bRevCount
                bId = booksData(0, r)
                bTitle = booksData(1, r)
                bIsbn = booksData(2, r)
                bPub = booksData(3, r)
                bPrice = booksData(4, r)
                bCopies = SafeInt(booksData(5, r), 0)
                bIsAvail = CBool(booksData(6, r))
                bAuthor = booksData(7, r)
                bCategory = booksData(8, r)
                bRating = Round(SafeFloat(booksData(9, r), 0), 1)
                bRevCount = SafeInt(booksData(10, r), 0)
        %>
            <div class="book-card-3d spotlight-card"
                 data-book-trigger
                 data-book-json='{"id":<%= bId %>,"title":<%= ToJSONString(bTitle) %>,"author":<%= ToJSONString(bAuthor) %>,"category":<%= ToJSONString(bCategory) %>,"isbn":<%= ToJSONString(bIsbn) %>,"publisher":<%= ToJSONString(bPub) %>,"price":"<%= FormatNumber(SafeFloat(bPrice, 0), 2) %>","available_copies":<%= bCopies %>,"can_edit":<%= IIf(IsStaff(), "true", "false") %>}'>

                <!-- 3D Book Cover Stage -->
                <div class="book-cover-stage">
                    <div class="book-3d-model">
                        <div class="book-front-cover">
                            <span class="book-cover-badge"><%= CleanText(bCategory & "") %></span>
                            <div class="book-cover-title"><%= CleanText(bTitle & "") %></div>
                            <div class="book-cover-author"><%= CleanText(bAuthor & "") %></div>
                        </div>
                    </div>
                </div>

                <!-- Card Body Details -->
                <div class="book-details-wrap">
                    <div class="book-meta-title"><%= CleanText(bTitle & "") %></div>
                    <div class="book-meta-author"><%= CleanText(bAuthor & "") %></div>

                    <div class="book-meta-chips">
                        <span class="meta-chip"><%= CleanText(bCategory & "") %></span>
                        <% If bIsAvail And bCopies > 0 Then %>
                            <span class="badge badge-success"><span class="badge-dot"></span><%= bCopies %> in stock</span>
                        <% Else %>
                            <span class="badge badge-danger"><span class="badge-dot"></span>Out of stock</span>
                        <% End If %>
                    </div>

                    <div class="book-card-bottom">
                        <strong style="color:var(--success); font-size:15px;">&#8377;<%= FormatNumber(SafeFloat(bPrice, 0), 2) %></strong>
                        <div style="font-size:12px; color:var(--text-muted);">
                            <% If bRating > 0 Then %>
                                <span style="color:#eab308; font-weight:700;">★ <%= bRating %></span> (<%= bRevCount %>)
                            <% Else %>
                                No reviews
                            <% End If %>
                        </div>
                    </div>
                </div>
            </div>
        <%
            Next
        End If
        %>
    </div>

    <!-- VIEW 2: HIGH-DENSITY DATA TABLE -->
    <div id="catalogTableView" style="display:none;">
        <div class="table-responsive">
            <table id="booksTable">
                <thead>
                    <tr>
                        <th class="sortable">ID</th>
                        <th class="sortable">Book Title</th>
                        <th class="sortable">Author</th>
                        <th class="sortable">Category</th>
                        <th class="sortable">ISBN</th>
                        <th class="sortable">Price</th>
                        <th class="sortable">Rating</th>
                        <th>Status</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If Not hasBooks Then
                    %>
                        <tr>
                            <td colspan="9" style="text-align:center; padding:32px; color:var(--text-muted);">No books found.</td>
                        </tr>
                    <%
                    Else
                        For r = 0 To totalRecords
                            bId = booksData(0, r)
                            bTitle = booksData(1, r)
                            bIsbn = booksData(2, r)
                            bPub = booksData(3, r)
                            bPrice = booksData(4, r)
                            bCopies = SafeInt(booksData(5, r), 0)
                            bIsAvail = CBool(booksData(6, r))
                            bAuthor = booksData(7, r)
                            bCategory = booksData(8, r)
                            bRating = Round(SafeFloat(booksData(9, r), 0), 1)
                            bRevCount = SafeInt(booksData(10, r), 0)
                    %>
                        <tr data-book-json='{"id":<%= bId %>,"title":<%= ToJSONString(bTitle) %>,"author":<%= ToJSONString(bAuthor) %>,"category":<%= ToJSONString(bCategory) %>,"isbn":<%= ToJSONString(bIsbn) %>,"publisher":<%= ToJSONString(bPub) %>,"price":"<%= FormatNumber(SafeFloat(bPrice, 0), 2) %>","available_copies":<%= bCopies %>,"can_edit":<%= IIf(IsStaff(), "true", "false") %>}'>
                            <td><strong>#<%= bId %></strong></td>
                            <td style="cursor:pointer;" data-book-trigger>
                                <strong style="color:var(--text-primary); font-size:14px;"><%= CleanText(bTitle & "") %></strong>
                                <% If bPub <> "" Then %>
                                    <div style="font-size:11.5px; color:var(--text-muted);"><%= CleanText(bPub & "") %></div>
                                <% End If %>
                            </td>
                            <td><%= CleanText(bAuthor & "") %></td>
                            <td><span class="meta-chip"><%= CleanText(bCategory & "") %></span></td>
                            <td><code><%= CleanText(bIsbn & "") %></code></td>
                            <td><strong style="color:var(--success);">&#8377;<%= FormatNumber(SafeFloat(bPrice, 0), 2) %></strong></td>
                            <td>
                                <% If bRating > 0 Then %>
                                    <span style="color:#eab308; font-weight:700;">★ <%= bRating %></span>
                                <% Else %>
                                    <span style="color:var(--text-muted); font-size:11px;">—</span>
                                <% End If %>
                            </td>
                            <td>
                                <% If bIsAvail And bCopies > 0 Then %>
                                    <span class="badge badge-success"><span class="badge-dot"></span><%= bCopies %> Avail</span>
                                <% Else %>
                                    <span class="badge badge-danger"><span class="badge-dot"></span>Out</span>
                                <% End If %>
                            </td>
                            <td style="text-align:right;">
                                <div style="display:inline-flex; gap:6px;">
                                    <button type="button" class="btn btn-secondary btn-sm" data-book-trigger>Inspect</button>
                                    <% If bIsAvail And bCopies > 0 And HasPermission("requests") Then %>
                                        <a href="request_book.asp?id=<%= bId %>" class="btn btn-primary btn-sm">Reserve</a>
                                    <% End If %>
                                </div>
                            </td>
                        </tr>
                    <%
                        Next
                    End If
                    %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- VIEW 3: COMPACT HIGH-DENSITY LIST -->
    <div id="catalogCompactView" class="books-compact-list" style="display:none;">
        <%
        If hasBooks Then
            For r = 0 To totalRecords
                bId = booksData(0, r)
                bTitle = booksData(1, r)
                bIsbn = booksData(2, r)
                bPub = booksData(3, r)
                bPrice = booksData(4, r)
                bCopies = SafeInt(booksData(5, r), 0)
                bIsAvail = CBool(booksData(6, r))
                bAuthor = booksData(7, r)
                bCategory = booksData(8, r)
        %>
            <div class="compact-book-row"
                 data-book-trigger
                 data-book-json='{"id":<%= bId %>,"title":<%= ToJSONString(bTitle) %>,"author":<%= ToJSONString(bAuthor) %>,"category":<%= ToJSONString(bCategory) %>,"isbn":<%= ToJSONString(bIsbn) %>,"publisher":<%= ToJSONString(bPub) %>,"price":"<%= FormatNumber(SafeFloat(bPrice, 0), 2) %>","available_copies":<%= bCopies %>,"can_edit":<%= IIf(IsStaff(), "true", "false") %>}'>
                <div class="compact-col-title">
                    <strong style="color:var(--text-primary); font-size:14px;"><%= CleanText(bTitle & "") %></strong>
                </div>
                <div class="compact-col-author">
                    <%= CleanText(bAuthor & "") %>
                </div>
                <div class="compact-col-category">
                    <span class="meta-chip"><%= CleanText(bCategory & "") %></span>
                </div>
                <div class="compact-col-stock">
                    <% If bIsAvail And bCopies > 0 Then %>
                        <span class="badge badge-success"><%= bCopies %> in stock</span>
                    <% Else %>
                        <span class="badge badge-danger">Out</span>
                    <% End If %>
                </div>
                <div class="compact-col-actions" onclick="event.stopPropagation();">
                    <% If bIsAvail And bCopies > 0 And HasPermission("requests") Then %>
                        <a href="request_book.asp?id=<%= bId %>" class="btn btn-primary btn-sm">Reserve</a>
                    <% End If %>
                    <button type="button" class="btn btn-secondary btn-sm" data-book-trigger>Inspect &rarr;</button>
                </div>
            </div>
        <%
            Next
        End If
        %>
    </div>
</div>

<% RenderFooter %>
