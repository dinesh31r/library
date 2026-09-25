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

' Handle Form Submissions (Add / Delete Category)
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim actionType
    actionType = Request.Form("action_type")

    If actionType = "add" Then
        Dim name, description
        name = Trim(Request.Form("name"))
        description = Trim(Request.Form("description"))

        If name = "" Then
            errorMessage = "Category Name is required."
        Else
            On Error Resume Next
            conn.Execute("INSERT INTO Categories (name, description) VALUES (" & SQLQuote(name) & ", " & SQLQuote(description) & ")")
            If Err.Number <> 0 Then
                errorMessage = "Failed to add category: " & Err.Description
            Else
                successMessage = "Category added successfully."
            End If
            On Error GoTo 0
        End If

    ElseIf actionType = "disable" Or actionType = "delete" Then
        Dim categoryId
        categoryId = SafeInt(Request.Form("category_id"), 0)
        If categoryId > 0 Then
            On Error Resume Next
            conn.Execute("UPDATE Categories SET is_active = 0 WHERE id = " & categoryId)
            If Err.Number <> 0 Then
                errorMessage = "Failed to disable category: " & Err.Description
            Else
                successMessage = "Category disabled successfully (preserved in database)."
            End If
            On Error GoTo 0
        End If

    ElseIf actionType = "enable" Then
        Dim categoryIdEnable
        categoryIdEnable = SafeInt(Request.Form("category_id"), 0)
        If categoryIdEnable > 0 Then
            On Error Resume Next
            conn.Execute("UPDATE Categories SET is_active = 1 WHERE id = " & categoryIdEnable)
            If Err.Number <> 0 Then
                errorMessage = "Failed to enable category: " & Err.Description
            Else
                successMessage = "Category enabled successfully."
            End If
            On Error GoTo 0
        End If
    End If
End If

' Fetch Categories List
Dim rsCategories
Set rsCategories = conn.Execute("SELECT id, name, description, is_active FROM Categories ORDER BY is_active DESC, name ASC")

RenderHeader "Categories Management"
%>

<!-- Header -->
<div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px; margin-bottom: 22px;">
    <div>
        <h1 style="font-size:22px; font-weight:800; color:var(--text-primary); margin-bottom:4px;">Book Categories Directory</h1>
        <p style="font-size:13px; color:var(--text-muted); margin:0;">Organize library literature by genres, subjects, and languages</p>
    </div>
</div>

<% If errorMessage <> "" Then %>
    <div class="alert alert-danger"><%= Server.HTMLEncode(errorMessage) %></div>
<% End If %>

<% If successMessage <> "" Then %>
    <div class="alert alert-info"><%= Server.HTMLEncode(successMessage) %></div>
<% End If %>

<div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap:24px;">
    <!-- Add Category Form Card -->
    <div class="card" style="align-self:start;">
        <div class="card-header">
            <h2 class="card-title">
                <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" /></svg>
                Create New Category
            </h2>
        </div>

        <form action="categories.asp" method="POST">
            <input type="hidden" name="action_type" value="add">

            <div class="form-group">
                <label for="name">Category Name *</label>
                <input type="text" id="name" name="name" class="form-control" required placeholder="e.g. Kannada Literature / Defence Radar Systems">
            </div>

            <div class="form-group">
                <label for="description">Description / Scope</label>
                <textarea id="description" name="description" class="form-control" rows="4" placeholder="Brief subject scope or target audience..."></textarea>
            </div>

            <button type="submit" class="btn btn-primary" style="width:100%; padding:10px;">
                + Save Category Record
            </button>
        </form>
    </div>

    <!-- Categories List Table Card -->
    <div class="card" style="padding:0; overflow:hidden;">
        <div style="padding:16px 20px; border-bottom:1px solid var(--border-subtle); display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
            <h2 class="card-title" style="margin:0;">Registered Categories</h2>
            <input type="text" class="search-input" data-live-filter="categoriesTable" placeholder="Instant filter categories..." style="padding:6px 12px; font-size:12.5px; width:200px;">
        </div>

        <div class="table-responsive">
            <table id="categoriesTable">
                <thead>
                    <tr>
                        <th class="sortable">ID</th>
                        <th class="sortable">Category Name</th>
                        <th>Description</th>
                        <th class="sortable" style="text-align:center;">Status</th>
                        <th style="text-align:right;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    If rsCategories Is Nothing Or rsCategories.State = 0 Or rsCategories.EOF Then
                    %>
                        <tr>
                            <td colspan="5" style="text-align:center; padding:32px; color:var(--text-muted);">No categories registered.</td>
                        </tr>
                    <%
                    Else
                        Do While Not rsCategories.EOF
                            Dim isCatActive
                            isCatActive = (SafeInt(rsCategories("is_active"), 1) = 1)
                    %>
                        <tr style="<%= IIf(Not isCatActive, "opacity: 0.72; background: rgba(0,0,0,0.015);", "") %>">
                            <td><strong>#<%= rsCategories("id") %></strong></td>
                            <td><strong style="color:var(--text-primary);"><%= Server.HTMLEncode(rsCategories("name") & "") %></strong></td>
                            <td><span style="color:var(--text-secondary); font-size:13px;"><%= Server.HTMLEncode(rsCategories("description") & "") %></span></td>
                            <td style="text-align:center;">
                                <% If isCatActive Then %>
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
                                <% If isCatActive Then %>
                                    <form action="categories.asp" method="POST" style="margin:0; display:inline;" onsubmit="return confirm('Disable this category? Record will remain preserved in the database.');">
                                        <input type="hidden" name="action_type" value="disable">
                                        <input type="hidden" name="category_id" value="<%= rsCategories("id") %>">
                                        <button type="submit" class="btn btn-warning btn-sm" onclick="return confirm('Disable this category? Record will remain preserved in the database.');" style="background: rgba(245, 158, 11, 0.12); color: #b45309; border: 1px solid rgba(245, 158, 11, 0.3); font-weight: 600; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                                            Disable
                                        </button>
                                    </form>
                                <% Else %>
                                    <form action="categories.asp" method="POST" style="margin:0; display:inline;" onsubmit="return confirm('Re-enable this category?');">
                                        <input type="hidden" name="action_type" value="enable">
                                        <input type="hidden" name="category_id" value="<%= rsCategories("id") %>">
                                        <button type="submit" class="btn btn-success btn-sm" onclick="return confirm('Re-enable this category?');" style="background: rgba(16, 185, 129, 0.12); color: #047857; border: 1px solid rgba(16, 185, 129, 0.3); font-weight: 600; padding: 4px 10px; border-radius: 6px; cursor: pointer;">
                                            Enable
                                        </button>
                                    </form>
                                <% End If %>
                            </td>
                        </tr>
                    <%
                            rsCategories.MoveNext
                        Loop
                        rsCategories.Close
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
