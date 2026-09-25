<!--#include file="includes/db_config.asp"-->
<%
' Require Authentication & Admin Security Guard
RequireAuth()
If Not IsAdmin() Then
    Response.Redirect("dashboard.asp?msg=Access+Denied:+Admin+only")
    Response.End
End If

Dim conn, errorMessage, successMessage
errorMessage = ""
successMessage = ""
Set conn = GetConnection()

' Handle Permission Updates (POST)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim userId, pBooks, pRequests, pBorrowings, pAuthors, pCategories, pFeedback
    
    On Error Resume Next
    Dim rsUsersList
    Set rsUsersList = conn.Execute("SELECT id FROM Users WHERE role <> 'Admin'")
    
    If Not (rsUsersList Is Nothing Or rsUsersList.State = 0) Then
        Do While Not rsUsersList.EOF
            userId = rsUsersList("id")
            
            pBooks = IIf(Request.Form("perm_books_" & userId) = "1", 1, 0)
            pRequests = IIf(Request.Form("perm_requests_" & userId) = "1", 1, 0)
            pBorrowings = IIf(Request.Form("perm_borrowings_" & userId) = "1", 1, 0)
            pAuthors = IIf(Request.Form("perm_authors_" & userId) = "1", 1, 0)
            pCategories = IIf(Request.Form("perm_categories_" & userId) = "1", 1, 0)
            pFeedback = IIf(Request.Form("perm_feedback_" & userId) = "1", 1, 0)
            
            conn.Execute("UPDATE Users SET " & _
                "perm_books = " & pBooks & ", " & _
                "perm_requests = " & pRequests & ", " & _
                "perm_borrowings = " & pBorrowings & ", " & _
                "perm_authors = " & pAuthors & ", " & _
                "perm_categories = " & pCategories & ", " & _
                "perm_feedback = " & pFeedback & " " & _
                "WHERE id = " & userId)
                
            rsUsersList.MoveNext
        Loop
        rsUsersList.Close
    End If
    
    If Err.Number <> 0 Then
        errorMessage = "Error updating permissions: " & Err.Description
    Else
        successMessage = "User feature permissions updated successfully!"
    End If
    On Error GoTo 0
End If

' Fetch all non-admin users
Dim rsUsers
Set rsUsers = conn.Execute("SELECT id, username, email, role, perm_books, perm_requests, perm_borrowings, perm_authors, perm_categories, perm_feedback FROM Users ORDER BY role ASC, username ASC")

RenderHeader "Manage Permissions"
%>

<!-- Header -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 22px;">
    <div>
        <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Role &amp; Feature Access Control (RBAC)</h1>
        <p style="font-size:13px; color:var(--text-muted); margin:0;">Configure module permissions for individual staff members and registered readers</p>
    </div>
</div>

<% If errorMessage <> "" Then %>
    <div class="alert alert-danger"><%= Server.HTMLEncode(errorMessage) %></div>
<% End If %>

<% If successMessage <> "" Then %>
    <div class="alert alert-info"><%= Server.HTMLEncode(successMessage) %></div>
<% End If %>

<form action="manage_permissions.asp" method="POST">
    <div class="card" style="padding:16px 20px; margin-bottom:20px;">
        <div class="search-input-wrap">
            <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" style="display:none;">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input type="text" class="search-input" data-live-filter="permissionsTable" placeholder="Search..." style="background:transparent; border:none; padding:0; font-size:13px; color:var(--text-primary);">
        </div>
    </div>

    <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-responsive">
            <table id="permissionsTable">
                <thead>
                    <tr>
                        <th class="sortable">User / Role</th>
                        <th class="sortable">Email Address</th>
                        <th style="text-align:center;">Books</th>
                        <th style="text-align:center;">Requests</th>
                        <th style="text-align:center;">Borrowings</th>
                        <th style="text-align:center;">Authors</th>
                        <th style="text-align:center;">Categories</th>
                        <th style="text-align:center;">Feedback</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If rsUsers Is Nothing Or rsUsers.State = 0 Or rsUsers.EOF Then
                    %>
                        <tr>
                            <td colspan="8" style="text-align:center; padding:32px; color:var(--text-muted);">No users found in database.</td>
                        </tr>
                    <%
                    Else
                        Do While Not rsUsers.EOF
                            Dim uId, uRole, roleBadgeStyle
                            uId = rsUsers("id")
                            uRole = rsUsers("role")
                            
                            If uRole = "Admin" Then
                                roleBadgeStyle = "badge-danger"
                            ElseIf uRole = "Librarian" Then
                                roleBadgeStyle = "badge-info"
                            Else
                                roleBadgeStyle = "badge-success"
                            End If
                    %>
                        <tr>
                            <td>
                                <strong style="color:var(--text-primary); font-size:14px;"><%= Server.HTMLEncode(rsUsers("username") & "") %></strong>
                                <div style="margin-top:2px;">
                                    <span class="badge <%= roleBadgeStyle %>" style="font-size:10.5px; padding:2px 8px;">
                                        <span class="badge-dot"></span><%= uRole %>
                                    </span>
                                </div>
                            </td>
                            <td><code><%= Server.HTMLEncode(rsUsers("email") & "") %></code></td>
                            <% If uRole = "Admin" Then %>
                                <td colspan="6" style="text-align:center; color:var(--brand-primary); font-weight:700; font-size:12.5px;">
                                    Full Administrator Authority (Unrestricted)
                                </td>
                            <% Else %>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_books_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_books")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_requests_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_requests")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_borrowings_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_borrowings")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_authors_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_authors")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_categories_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_categories")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                                <td style="text-align:center;">
                                    <input type="checkbox" name="perm_feedback_<%= uId %>" value="1" <%= IIf(CBool(rsUsers("perm_feedback")), "checked", "") %> style="width:18px; height:18px; cursor:pointer;">
                                </td>
                            <% End If %>
                        </tr>
                    <%
                            rsUsers.MoveNext
                        Loop
                        rsUsers.Close
                    End If
                    
                    conn.Close
                    Set conn = Nothing
                    %>
                </tbody>
            </table>
        </div>

        <div style="padding:18px 24px; border-top:1px solid var(--border-subtle); background:var(--bg-surface-subtle); display:flex; justify-content:flex-end;">
            <button type="submit" class="btn btn-primary" style="padding:10px 24px; font-size:14px;">
                Save Permission Matrix
            </button>
        </div>
    </div>
</form>

<% RenderFooter %>
