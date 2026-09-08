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

<% If IsStaff() Then %>
    <div class="card">
        <div class="card-header">
            <h2 style="margin:0; color:#2c3e50;">Issue / Borrow Book</h2>
        </div>

        <% If errorMessage <> "" Then %>
            <div class="alert alert-danger"><%= CleanText(errorMessage) %></div>
        <% End If %>

        <% If successMessage <> "" Then %>
            <div class="alert alert-info"><%= CleanText(successMessage) %></div>
        <% End If %>

        <form action="borrowings.asp" method="POST" style="display:grid; grid-template-columns: 2fr 2fr 1fr 1fr; gap:15px; align-items:end;">
            <input type="hidden" name="action_type" value="issue">

            <div class="form-group" style="margin-bottom:0;">
                <label for="book_id">Select Book</label>
                <select id="book_id" name="book_id" required>
                    <option value="">-- Choose Book --</option>
                    <%
                    If Not rsBooks Is Nothing And rsBooks.State = 1 Then
                        Do While Not rsBooks.EOF
                    %>
                        <option value="<%= rsBooks("id") %>"><%= CleanText(rsBooks("title") & "") %> (<%= rsBooks("copies_available") %> left)</option>
                    <%
                            rsBooks.MoveNext
                        Loop
                    End If
                    %>
                </select>
            </div>

            <div class="form-group" style="margin-bottom:0;">
                <label for="user_id">Select Staff Member</label>
                <select id="user_id" name="user_id" required>
                    <option value="">-- Choose Staff Member --</option>
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
                <label for="days">Days Due (Standard: 15)</label>
                <input type="number" id="days" name="days" value="15" min="1" required>
            </div>

            <div>
                <button type="submit" class="btn btn-success" style="width:100%; padding:10px;">Issue Book</button>
            </div>
        </form>
    </div>
<% End If %>

<div class="card">
    <div class="card-header">
        <div>
            <h3 style="margin:0; color:#2c3e50;"><%= IIf(IsStaff(), "Active & Past Borrowing Log", "My Borrowed Books History") %></h3>
            <% If IsStaff() Then %>
                <p style="margin:4px 0 0 0; color:#e74c3c; font-size:13px; font-weight:600;">🚨 Note: Borrowings reaching day 16 (past 15-day return limit) are highlighted in bright red.</p>
            <% End If %>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Book Title</th>
                <% If IsStaff() Then %>
                    <th>Staff Name</th>
                <% End If %>
                <th>Borrowed On</th>
                <th>Due On (Day 15)</th>
                <th>Returned On</th>
                <th>Status</th>
                <% If IsStaff() Then %>
                    <th>Action</th>
                <% End If %>
            </tr>
        </thead>
        <tbody>
            <%
            If rsList Is Nothing Or rsList.State = 0 Or rsList.EOF Then
            %>
                <tr>
                    <td colspan="<%= IIf(IsStaff(), 8, 6) %>" style="text-align:center; color:#95a5a6;">No borrowing transactions found.</td>
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
                        rowStyle = "style='background-color:#fce4e4; color:#721c24; border-left: 6px solid #e74c3c; font-weight:bold;'"
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
                    <td>#<%= rsList("id") %></td>
                    <td><strong style="color:#2c3e50;"><%= CleanText(rsList("title") & "") %></strong></td>
                    <% If IsStaff() Then %>
                        <td><%= CleanText(rsList("username") & "") %></td>
                    <% End If %>
                    <td><%= fmtBorrowDate %></td>
                    <td><%= fmtDueDate %></td>
                    <td>
                        <% If fmtReturnDate <> "-" Then %>
                            <%= fmtReturnDate %>
                        <% Else %>
                            <span style="color:#95a5a6;">-</span>
                        <% End If %>
                    </td>
                    <td>
                        <% If isOverdueRed Then %>
                            <span class="badge bg-danger" style="font-size:12px;">🚨 OVERDUE (Day 16+)</span>
                        <% ElseIf bStatus = "Returned" Then %>
                            <span class="badge bg-success">Returned</span>
                        <% Else %>
                            <span class="badge bg-warning">Borrowed</span>
                        <% End If %>
                    </td>
                    <% If IsStaff() Then %>
                        <td>
                            <% If bStatus <> "Returned" Then %>
                                <form action="borrowings.asp" method="POST" style="display:inline-block;">
                                    <input type="hidden" name="action_type" value="return">
                                    <input type="hidden" name="borrow_id" value="<%= rsList("id") %>">
                                    <button type="submit" class="btn btn-primary" style="padding:4px 8px; font-size:12px;">Mark Returned</button>
                                </form>
                            <% Else %>
                                <span style="color:#95a5a6; font-size:12px;">Completed</span>
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

<% RenderFooter %>
