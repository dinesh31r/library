<!--#include file="includes/db_config.asp"-->
<%
' ====================================================================
' Login Module (.asp VBScript Backend)
' ====================================================================
Dim errorMessage, msg
errorMessage = ""
msg = Request.QueryString("msg")

' Handle Form Submission (POST)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim email, password
    email = Trim(Request.Form("email"))
    password = Trim(Request.Form("password"))

    If email = "" Or password = "" Then
        errorMessage = "Email and Password are required."
    Else
        Dim conn, rs, sql
        Set conn = GetConnection()

        sql = "SELECT id, email, username, role, password_hash, perm_books, perm_requests, perm_borrowings, perm_authors, perm_categories, perm_feedback FROM Users WHERE email = " & SQLQuote(email)
        Set rs = Server.CreateObject("ADODB.Recordset")
        
        On Error Resume Next
        rs.Open sql, conn, 1, 1

        If Err.Number <> 0 Then
            ' Fallback for default admin testing
            If email = "admin@bel.com" And password = "Password123!" Then
                Session("UserId") = 1
                Session("Username") = "Admin User"
                Session("Role") = "Admin"
                Session("Perm_books") = True
                Session("Perm_requests") = True
                Session("Perm_borrowings") = True
                Session("Perm_authors") = True
                Session("Perm_categories") = True
                Session("Perm_feedback") = True
                Response.Redirect("dashboard.asp")
                Response.End
            Else
                errorMessage = "Authentication table query error: " & Err.Description
            End If
            Err.Clear
        ElseIf Not rs.EOF Then
            ' Verify password match
            If rs("password_hash") = password Then
                Session("UserId") = rs("id")
                Session("Username") = rs("username")
                Session("Role") = rs("role")
                
                ' Load User Feature Permissions into Session
                On Error Resume Next
                Session("Perm_books") = CBool(rs("perm_books"))
                Session("Perm_requests") = CBool(rs("perm_requests"))
                Session("Perm_borrowings") = CBool(rs("perm_borrowings"))
                Session("Perm_authors") = CBool(rs("perm_authors"))
                Session("Perm_categories") = CBool(rs("perm_categories"))
                Session("Perm_feedback") = CBool(rs("perm_feedback"))
                On Error GoTo 0

                rs.Close
                conn.Close
                Set rs = Nothing
                Set conn = Nothing

                Response.Redirect("dashboard.asp")
                Response.End
            Else
                errorMessage = "Invalid email or password."
                rs.Close
                conn.Close
                Set rs = Nothing
                Set conn = Nothing
            End If
        Else
            errorMessage = "Invalid email or password."
            rs.Close
            conn.Close
            Set rs = Nothing
            Set conn = Nothing
        End If
        On Error GoTo 0
    End If
End If

RenderHeader "Login"
%>

<div style="max-width: 480px; margin: 40px auto;" class="card">
    <h2 style="margin-top:0; text-align: center; color:#2c3e50;">Sign In</h2>
    <p style="text-align: center; color:#7f8c8d;">BEL Library System - Multi-Role Access</p>

    <% If msg <> "" Then %>
        <div class="alert alert-info"><%= Server.HTMLEncode(msg) %></div>
    <% End If %>

    <% If errorMessage <> "" Then %>
        <div class="alert alert-danger"><%= Server.HTMLEncode(errorMessage) %></div>
    <% End If %>

    <form action="login.asp" method="POST">
        <div class="form-group">
            <label for="email">Email Address</label>
            <input type="email" id="email" name="email" placeholder="user@bel.com" required>
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password" id="password" name="password" placeholder="••••••••" required>
        </div>

        <button type="submit" class="btn btn-primary" style="width:100%; padding:10px;">Sign In</button>
    </form>
    
    <div style="margin-top:24px; padding-top:16px; border-top:1px solid #eee; font-size:12px; color:#555;">
        <strong>Available Test Accounts (Password: <code>Password123!</code>):</strong>
        <ul style="margin: 8px 0 0 0; padding-left: 20px;">
            <li><strong>Admin:</strong> <code>admin@bel.com</code></li>
            <li><strong>Librarian:</strong> <code>librarian@bel.com</code></li>
            <li><strong>Member:</strong> <code>john.doe@bel.com</code></li>
        </ul>
    </div>
</div>

<% RenderFooter %>
