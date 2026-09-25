<!--#include file="includes/db_config.asp"-->
<%
RequireAuth()

Dim conn, errorMessage, successMessage
Dim actionType, bookId, userId, days, todayStr, dueStr, insertSql, borrowId, retDateStr
Dim rsBooks, rsUsers, rsList, sqlList, currentUserId
Dim bStatus, bBorrowDate, bDueDate, bReturnDate, isOverdueRed, rowStyle, fmtBorrowDate, fmtDueDate, fmtReturnDate

errorMessage = ""
successMessage = ""
Set conn = GetConnection()

' --------------------------------------------------------------------
' Auto-Update Overdue Status (Mark Overdue if CURRENT_DATE > due_date)
' --------------------------------------------------------------------
On Error Resume Next
conn.Execute("UPDATE Borrowings SET status = 'Overdue' WHERE status = 'Borrowed' AND due_date < CURRENT_DATE()")
On Error GoTo 0

' Handle Form Action (Issue Book / Return Book) - Staff Only
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    If Not IsStaff() Then
        errorMessage = "Only library staff (Admin/Librarian) can issue or process book returns."
    Else
        actionType = Request.Form("action_type")

        If actionType = "issue" Then
            bookId = SafeInt(Request.Form("book_id"), 0)
            userId = SafeInt(Request.Form("user_id"), 0)
            days = SafeInt(Request.Form("days"), 15)

            If bookId = 0 Or userId = 0 Then
                errorMessage = "Please select both a Book and a Staff Member."
            Else
                todayStr = Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & Right("0" & Day(Now), 2)
                dueStr = Year(DateAdd("d", days, Now)) & "-" & Right("0" & Month(DateAdd("d", days, Now)), 2) & "-" & Right("0" & Day(DateAdd("d", days, Now)), 2)

                insertSql = "INSERT INTO Borrowings (book_id, user_id, borrow_date, due_date, status) VALUES (" & _
                            bookId & ", " & userId & ", " & SQLQuote(todayStr) & ", " & SQLQuote(dueStr) & ", 'Borrowed')"

                On Error Resume Next
                conn.Execute(insertSql)
                ' Decrease copy count
                conn.Execute("UPDATE Books SET copies_available = copies_available - 1 WHERE id = " & bookId & " AND copies_available > 0")
                If Err.Number <> 0 Then
                    errorMessage = "Issue Book Error: " & Err.Description
                Else
                    successMessage = "Book issued successfully for " & days & " days."
                End If
                On Error GoTo 0
            End If

        ElseIf actionType = "return" Then
            borrowId = SafeInt(Request.Form("borrow_id"), 0)
            If borrowId > 0 Then
                retDateStr = Year(Now) & "-" & Right("0" & Month(Now), 2) & "-" & Right("0" & Day(Now), 2)

                On Error Resume Next
                ' Update borrowing status
                conn.Execute("UPDATE Borrowings SET status = 'Returned', return_date = " & SQLQuote(retDateStr) & " WHERE id = " & borrowId)
                
                ' Increment available book copy count
                conn.Execute("UPDATE Books SET copies_available = copies_available + 1 WHERE id = (SELECT book_id FROM Borrowings WHERE id = " & borrowId & ")")
                If Err.Number <> 0 Then
                    errorMessage = "Return Book Error: " & Err.Description
                Else
                    successMessage = "Book returned successfully."
                End If
                On Error GoTo 0
            End If
        End If
    End If
End If

' Fetch Available Books & Users for Select Dropdowns (Staff view)
If IsStaff() Then
    Set rsBooks = conn.Execute("SELECT id, title, copies_available FROM Books WHERE copies_available > 0 ORDER BY title ASC")
    Set rsUsers = conn.Execute("SELECT id, username, email FROM Users ORDER BY username ASC")
End If

' Fetch Borrowing Records List
If IsStaff() Then
    sqlList = "SELECT b.id, bk.title, u.username, b.borrow_date, b.due_date, b.return_date, b.status " & _
              "FROM Borrowings b " & _
              "LEFT JOIN Books bk ON b.book_id = bk.id " & _
              "LEFT JOIN Users u ON b.user_id = u.id " & _
              "ORDER BY b.id DESC"
Else
    currentUserId = SafeInt(Session("UserId"), 0)
    sqlList = "SELECT b.id, bk.title, u.username, b.borrow_date, b.due_date, b.return_date, b.status " & _
              "FROM Borrowings b " & _
              "LEFT JOIN Books bk ON b.book_id = bk.id " & _
              "LEFT JOIN Users u ON b.user_id = u.id " & _
              "WHERE b.user_id = " & currentUserId & " " & _
              "ORDER BY b.id DESC"
End If

Set rsList = conn.Execute(sqlList)

RenderHeader IIf(IsStaff(), "Book Borrowing Management", "My Borrowed Books")
%>

<!-- Header & Actions -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 22px;">
    <div>
        <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">
            <%= IIf(IsStaff(), "Borrowing Transactions & Issue Desk", "My Borrowed Books History") %>
        </h1>
        <p style="font-size:13px; color:var(--text-muted); margin:0;">
            Track active book loans, process returns, and monitor overdue deadlines.
        </p>
    </div>

    <% If Not IsStaff() Then %>
        <a href="request_book.asp" class="btn btn-primary">+ Request a Book</a>
    <% End If %>
</div>

<% If errorMessage <> "" Then %>
    <div class="alert alert-danger"><%= CleanText(errorMessage) %></div>
<% End If %>

<% If successMessage <> "" Then %>
    <div class="alert alert-info"><%= CleanText(successMessage) %></div>
<% End If %>

<% If IsStaff() Then %>
    <!-- Issue Book Desk Card -->
    <div class="card" style="margin-bottom:22px;">
        <div class="card-header">
            <h2 class="card-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                Issue / Check Out Book
            </h2>
            <span style="font-size:12.5px; color:var(--text-muted);">Standard borrowing term: 15 days</span>
        </div>

        <form action="borrowings.asp" method="POST" style="display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap:16px; align-items:end;">
            <input type="hidden" name="action_type" value="issue">

            <div class="form-group" style="margin-bottom:0;">
                <label for="book_id">Select Book</label>
                <select id="book_id" name="book_id" class="form-control" required>
                    <option value="">-- Choose Book from Shelves --</option>
                    <%
                    If Not rsBooks Is Nothing And rsBooks.State = 1 Then
                        Do While Not rsBooks.EOF
                    %>
                        <option value="<%= rsBooks("id") %>"><%= CleanText(rsBooks("title") & "") %> (<%= rsBooks("copies_available") %> in stock)</option>
                    <%
                            rsBooks.MoveNext
                        Loop
                    End If
                    %>
                </select>
            </div>

            <div class="form-group" style="margin-bottom:0;">
                <label for="user_id">Select Member / Staff</label>
                <select id="user_id" name="user_id" class="form-control" required>
                    <option value="">-- Choose Member Account --</option>
                    <%
                    If Not rsUsers Is Nothing And rsUsers.State = 1 Then
                        Do While Not rsUsers.EOF
                    %>
                        <option value="<%= rsUsers("id") %>"><%= CleanText(rsUsers("username") & " (" & rsUsers("email") & ")") %></option>
                    <%
                            rsUsers.MoveNext
                        Loop
                    End If
                    %>
                </select>
            </div>

            <div class="form-group" style="margin-bottom:0;">
                <label for="days">Loan Duration (Days)</label>
                <input type="number" id="days" name="days" class="form-control" value="15" min="1" max="90" required>
            </div>

            <div>
                <button type="submit" class="btn btn-primary" style="width:100%; height:42px;">
                    <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
                    Issue Book
                </button>
            </div>
        </form>
    </div>
<% End If %>

<!-- Search & Table Card -->
<div class="card" style="padding:16px 20px; margin-bottom:20px;">
    <div class="search-input-wrap">
        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" style="display:none;">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input type="text" class="search-input" data-live-filter="borrowingsTable" placeholder="Search..." style="background:transparent; border:none; padding:0; font-size:13px; color:var(--text-primary);">
    </div>
</div>

<div class="card" style="padding:0; overflow:hidden;">
    <div class="table-responsive">
        <table id="borrowingsTable">
            <thead>
                <tr>
                    <th class="sortable">ID</th>
                    <th class="sortable">Book Title</th>
                    <% If IsStaff() Then %>
                        <th class="sortable">Member / Staff</th>
                    <% End If %>
                    <th class="sortable">Borrowed On</th>
                    <th class="sortable">Due Date</th>
                    <th class="sortable">Returned On</th>
                    <th>Status</th>
                    <% If IsStaff() Then %>
                        <th style="text-align:right;">Action</th>
                    <% End If %>
                </tr>
            </thead>
            <tbody>
                <%
                If rsList Is Nothing Or rsList.State = 0 Or rsList.EOF Then
                %>
                    <tr>
                        <td colspan="<%= IIf(IsStaff(), 8, 6) %>" style="text-align:center; padding:32px; color:var(--text-muted);">No borrowing transactions found.</td>
                    </tr>
                <%
                Else
                    Do While Not rsList.EOF
                        bStatus = rsList("status") & ""
                        bBorrowDate = rsList("borrow_date")
                        bDueDate = rsList("due_date")
                        bReturnDate = rsList("return_date")
                        
                        isOverdueRed = False
                        If bStatus <> "Returned" And Not IsNull(bDueDate) And IsDate(bDueDate) Then
                            If Date > CDate(bDueDate) Then
                                isOverdueRed = True
                            End If
                        End If
                        
                        If isOverdueRed Then
                            rowStyle = "style='background-color:var(--danger-bg); border-left: 4px solid var(--danger); font-weight:600;'"
                        Else
                            rowStyle = ""
                        End If

                        If Not IsNull(bBorrowDate) And IsDate(bBorrowDate) Then
                            fmtBorrowDate = FormatDateTime(bBorrowDate, 2)
                        Else
                            fmtBorrowDate = "-"
                        End If

                        If Not IsNull(bDueDate) And IsDate(bDueDate) Then
                            fmtDueDate = FormatDateTime(bDueDate, 2)
                        Else
                            fmtDueDate = "-"
                        End If

                        If Not IsNull(bReturnDate) And IsDate(bReturnDate) Then
                            fmtReturnDate = FormatDateTime(bReturnDate, 2)
                        Else
                            fmtReturnDate = "-"
                        End If
                %>
                    <tr <%= rowStyle %>>
                        <td><strong>#<%= rsList("id") %></strong></td>
                        <td><strong style="color:var(--text-primary);"><%= CleanText(rsList("title") & "") %></strong></td>
                        <% If IsStaff() Then %>
                            <td><%= CleanText(rsList("username") & "") %></td>
                        <% End If %>
                        <td><%= fmtBorrowDate %></td>
                        <td><%= fmtDueDate %></td>
                        <td>
                            <% If fmtReturnDate <> "-" Then %>
                                <%= fmtReturnDate %>
                            <% Else %>
                                <span style="color:var(--text-muted);">-</span>
                            <% End If %>
                        </td>
                        <td>
                            <% If isOverdueRed Then %>
                                <span class="badge badge-danger"><span class="badge-dot"></span>Overdue (Day 16+)</span>
                            <% ElseIf bStatus = "Returned" Then %>
                                <span class="badge badge-success"><span class="badge-dot"></span>Returned</span>
                            <% Else %>
                                <span class="badge badge-warning"><span class="badge-dot"></span>Active Loan</span>
                            <% End If %>
                        </td>
                        <% If IsStaff() Then %>
                            <td style="text-align:right;">
                                <% If bStatus <> "Returned" Then %>
                                    <form action="borrowings.asp" method="POST" style="margin:0; display:inline-block;">
                                        <input type="hidden" name="action_type" value="return">
                                        <input type="hidden" name="borrow_id" value="<%= rsList("id") %>">
                                        <button type="submit" class="btn btn-primary btn-sm">Process Return</button>
                                    </form>
                                <% Else %>
                                    <span style="color:var(--text-muted); font-size:12px;">Archived</span>
                                <% End If %>
                            </td>
                        <% End If %>
                    </tr>
                <%
                        rsList.MoveNext
                    Loop
                    rsList.Close
                End If

                conn.Close
                Set conn = Nothing
                %>
            </tbody>
        </table>
    </div>
</div>

<% RenderFooter %>
