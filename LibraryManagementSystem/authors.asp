<!--#include file="includes/db_config.asp"-->
<%
RequireAuth()

If Not IsStaff() Then
    Response.Redirect("dashboard.asp?msg=Access+denied")
    Response.End
End If

Dim conn, errorMessage, successMessage
errorMessage = ""
successMessage = ""
Set conn = GetConnection()

' Handle Form Submissions (Add / Delete Author)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim actionType
    actionType = Request.Form("action_type")

    If actionType = "add" Then
        Dim name, bio
        name = Trim(Request.Form("name"))
        bio = Trim(Request.Form("bio"))

        If name = "" Then
            errorMessage = "Author Name is required."
        Else
            On Error Resume Next
            conn.Execute("INSERT INTO Authors (name, bio) VALUES (" & SQLQuote(name) & ", " & SQLQuote(bio) & ")")
            If Err.Number <> 0 Then
                errorMessage = "Failed to add author: " & Err.Description
            Else
                successMessage = "Author added successfully."
            End If
            On Error GoTo 0
        End If

    ElseIf actionType = "disable" Or actionType = "delete" Then
        Dim authorId
        authorId = SafeInt(Request.Form("author_id"), 0)
        If authorId > 0 Then
            On Error Resume Next
            conn.Execute("UPDATE Authors SET is_active = 0 WHERE id = " & authorId)
            If Err.Number <> 0 Then
                errorMessage = "Failed to disable author: " & Err.Description
            Else
                successMessage = "Author disabled successfully (preserved in database)."
            End If
            On Error GoTo 0
        End If

    ElseIf actionType = "enable" Then
        Dim authorIdEnable
        authorIdEnable = SafeInt(Request.Form("author_id"), 0)
        If authorIdEnable > 0 Then
            On Error Resume Next
            conn.Execute("UPDATE Authors SET is_active = 1 WHERE id = " & authorIdEnable)
            If Err.Number <> 0 Then
                errorMessage = "Failed to enable author: " & Err.Description
            Else
                successMessage = "Author enabled successfully."
            End If
            On Error GoTo 0
        End If
    End If
End If

' Fetch Authors List
Dim rsAuthors
Set rsAuthors = conn.Execute("SELECT id, name, bio, is_active FROM Authors ORDER BY is_active DESC, name ASC")

RenderHeader "Authors Management"
%>

<!-- Header -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 22px;">
    <div>
        <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Authors Directory &amp; Management</h1>
        <p style="font-size:13px; color:var(--text-muted); margin:0;">Maintain library authors and biographical records</p>
    </div>
</div>

<% If errorMessage <> "" Then %>
    <div class="alert alert-danger"><%= Server.HTMLEncode(errorMessage) %></div>
<% End If %>

<% If successMessage <> "" Then %>
    <div class="alert alert-info"><%= Server.HTMLEncode(successMessage) %></div>
<% End If %>

<div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap:24px;">
    <!-- Add Author Form Card -->
    <div class="card" style="align-self:start;">
        <div class="card-header">
            <h2 class="card-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" /></svg>
                Register New Author
            </h2>
        </div>

        <form action="authors.asp" method="POST">
            <input type="hidden" name="action_type" value="add">

            <div class="form-group">
                <label for="name">Author Name *</label>
                <input type="text" id="name" name="name" class="form-control" required placeholder="e.g. Kuvempu / B.G.L. Swamy">
            </div>

            <div class="form-group">
                <label for="bio">Biography / Notes</label>
                <textarea id="bio" name="bio" class="form-control" rows="4" placeholder="Brief background, notable honors, or literary focus..."></textarea>
            </div>

            <button type="submit" class="btn btn-primary" style="width:100%; padding:10px;">
                + Save Author Record
            </button>
        </form>
    </div>

    <!-- Authors List Table Card -->
    <div class="card" style="padding:0; overflow:hidden;">
        <div style="padding:16px 20px; border-bottom:1px solid var(--border-subtle); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
            <h2 class="card-title" style="margin:0;">Registered Authors</h2>
            <input type="text" class="search-input" data-live-filter="authorsTable" placeholder="Instant filter authors..." style="padding:6px 12px; font-size:12.5px; width:200px;">
        </div>

        <div class="table-responsive">
            <table id="authorsTable">
                <thead>
                    <tr>
                        <th class="sortable">ID</th>
                        <th class="sortable">Name</th>
                        <th>Biography</th>
                        <th class="sortable" style="text-align:center;">Status</th>
                        <th style="text-align:right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If rsAuthors Is Nothing Or rsAuthors.State = 0 Or rsAuthors.EOF Then
                    %>
                        <tr>
                            <td colspan="5" style="text-align:center; padding:32px; color:var(--text-muted);">No authors registered.</td>
                        </tr>
                    <%
                    Else
                        Do While Not rsAuthors.EOF
                            Dim isAuthActive
                            isAuthActive = (SafeInt(rsAuthors("is_active"), 1) = 1)
                    %>
                        <tr style="<%= IIf(Not isAuthActive, "opacity: 0.72; background: rgba(0,0,0,0.015);", "") %>">
                            <td><strong>#<%= rsAuthors("id") %></strong></td>
                            <td><strong style="color:var(--text-primary);"><%= Server.HTMLEncode(rsAuthors("name") & "") %></strong></td>
                            <td><span style="color:var(--text-secondary); font-size:13px;"><%= Server.HTMLEncode(rsAuthors("bio") & "") %></span></td>
                            <td style="text-align:center;">
                                <% If isAuthActive Then %>
                                    <span class="badge" style="background: rgba(16, 185, 129, 0.12); color: #059669; border: 1px solid rgba(16, 185, 129, 0.3); font-weight: 600; padding: 3px 9px; border-radius: 9999px; font-size: 11.5px; display: inline-flex; align-items: center; gap: 4px;">
                                        <span style="width:6px; height:6px; border-radius:50%; background:#10b981;"></span>Active
                                    </span>
                                <% Else %>
                                    <span class="badge" style="background: rgba(100, 116, 139, 0.12); color: #64748b; border: 1px solid rgba(100, 116, 139, 0.3); font-weight: 600; padding: 3px 9px; border-radius: 9999px; font-size: 11.5px; display: inline-flex; align-items: center; gap: 4px;">
                                        <span style="width:6px; height:6px; border-radius:50%; background:#94a3b8;"></span>Disabled
                                    </span>
                                <% End If %>
                            </td>
                            <td style="text-align:right;">
                                <% If isAuthActive Then %>
                                    <form action="authors.asp" method="POST" style="margin:0; display:inline;" onsubmit="return confirm('Disable this author? Record will remain preserved in the database.');">
                                        <input type="hidden" name="action_type" value="disable">
                                        <input type="hidden" name="author_id" value="<%= rsAuthors("id") %>">
                                        <button type="submit" class="btn btn-warning btn-sm" onclick="return confirm('Disable this author? Record will remain preserved in the database.');" style="background: rgba(245, 158, 11, 0.12); color: #b45309; border: 1px solid rgba(245, 158, 11, 0.3); font-weight: 600; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                                            Disable
                                        </button>
                                    </form>
                                <% Else %>
                                    <form action="authors.asp" method="POST" style="margin:0; display:inline;" onsubmit="return confirm('Re-enable this author?');">
                                        <input type="hidden" name="action_type" value="enable">
                                        <input type="hidden" name="author_id" value="<%= rsAuthors("id") %>">
                                        <button type="submit" class="btn btn-success btn-sm" onclick="return confirm('Re-enable this author?');" style="background: rgba(16, 185, 129, 0.12); color: #047857; border: 1px solid rgba(16, 185, 129, 0.3); font-weight: 600; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                                            Enable
                                        </button>
                                    </form>
                                <% End If %>
                            </td>
                        </tr>
                    <%
                            rsAuthors.MoveNext
                        Loop
                        rsAuthors.Close
                    End If

                    conn.Close
                    Set conn = Nothing
                    %>
                </tbody>
            </table>
        </div>
    </div>
</div>

<% RenderFooter %>
