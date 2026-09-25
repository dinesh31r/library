<%@ Language=VBScript CodePage=65001 %>
<%
' ====================================================================
' Database Configuration & Shared Helpers for Classic ASP (.asp)
' UTF-8 / Kannada Script Support Enabled
' ====================================================================
Option Explicit

' Enable Response Buffering & UTF-8 Session/Output Encoding
Response.Buffer = True
Response.CodePage = 65001
Response.CharSet = "UTF-8"
Session.CodePage = 65001

' Safe UTF-8 HTML Text Escaping (preserves Unicode / Kannada scripts)
Function CleanText(val)
    If IsNull(val) Or val = "" Then
        CleanText = ""
    Else
        Dim s
        s = CStr(val)
        s = Replace(s, "&", "&amp;")
        s = Replace(s, "<", "&lt;")
        s = Replace(s, ">", "&gt;")
        s = Replace(s, """", "&quot;")
        CleanText = s
    End If
End Function

' --------------------------------------------------------------------
' Database Connection Function
' --------------------------------------------------------------------
Function GetConnection()
    Dim conn, connStr, drivers, passwords, d, p, connected
    Set conn = Server.CreateObject("ADODB.Connection")
    connected = False

    drivers = Array("{MySQL ODBC 26.7 Unicode Driver}", "{MySQL ODBC 26.7 ANSI Driver}", "{MySQL ODBC 8.0 Unicode Driver}", "{MySQL ODBC 8.0 ANSI Driver}", "{MySQL ODBC 5.3 Unicode Driver}")
    passwords = Array("", "root", "password")

    On Error Resume Next
    For Each d In drivers
        For Each p In passwords
            connStr = "DRIVER=" & d & ";SERVER=localhost;PORT=3306;DATABASE=LibraryDb;USER=root;PASSWORD=" & p & ";OPTION=3;STMT=SET NAMES utf8mb4;"
            Err.Clear
            conn.Open connStr
            If Err.Number = 0 Then
                connected = True
                Exit For
            End If
        Next
        If connected Then Exit For
    Next

    If Not connected Then
        Response.Write("<div style='color:red;font-family:sans-serif;'>")
        Response.Write("<h3>Database Connection Error</h3>")
        Response.Write("<p>" & Err.Description & "</p>")
        Response.Write("<p>Please verify connection string in <code>includes/db_config.asp</code>.</p>")
        Response.Write("</div>")
        Response.End
    End If
    On Error GoTo 0

    Set GetConnection = conn
End Function

' --------------------------------------------------------------------
' Role & Permission Helper Functions
' --------------------------------------------------------------------
Function IsAdmin()
    IsAdmin = (LCase(Trim(CStr(Session("Role") & ""))) = "admin")
End Function

Function IsLibrarian()
    IsLibrarian = (LCase(Trim(CStr(Session("Role") & ""))) = "librarian")
End Function

Function IsStaff()
    IsStaff = (IsAdmin() Or IsLibrarian())
End Function

Function IsMember()
    IsMember = (Not IsStaff())
End Function

Function HasPermission(permName)
    If IsAdmin() Then
        HasPermission = True
    Else
        Dim pKey
        pKey = "Perm_" & LCase(permName)
        If IsEmpty(Session(pKey)) Or Session(pKey) = "" Then
            ' Default permissions fallback
            If LCase(permName) = "authors" Or LCase(permName) = "categories" Then
                HasPermission = IsStaff()
            Else
                HasPermission = True
            End If
        Else
            HasPermission = (CBool(Session(pKey)) = True)
        End If
    End If
End Function

Function IIf(expr, trueVal, falseVal)
    If expr Then
        IIf = trueVal
    Else
        IIf = falseVal
    End If
End Function

' --------------------------------------------------------------------
' Session Authentication Guard
' --------------------------------------------------------------------
Sub RequireAuth()
    If IsEmpty(Session("UserId")) Or Session("UserId") = "" Then
        Response.Redirect("login.asp?msg=Please+login+to+continue")
        Response.End
    End If
End Sub

' --------------------------------------------------------------------
' SQL Sanitization Helper (Prevents SQL Injection in VBScript)
' --------------------------------------------------------------------
Function SQLQuote(value)
    If IsNull(value) Or IsEmpty(value) Then
        SQLQuote = "NULL"
    Else
        Dim sanitized
        sanitized = Replace(CStr(value), "'", "''")
        SQLQuote = "'" & sanitized & "'"
    End If
End Function

Function FormatSQLDate(dtVal)
    If IsNull(dtVal) Or IsEmpty(dtVal) Or dtVal = "" Then
        FormatSQLDate = "NULL"
    ElseIf IsDate(dtVal) Then
        Dim d
        d = CDate(dtVal)
        FormatSQLDate = "'" & Year(d) & "-" & Right("0" & Month(d), 2) & "-" & Right("0" & Day(d), 2) & "'"
    Else
        FormatSQLDate = SQLQuote(dtVal)
    End If
End Function

Function SafeInt(value, defaultVal)
    If IsNumeric(value) And Trim(value) <> "" Then
        SafeInt = CLng(value)
    Else
        SafeInt = defaultVal
    End If
End Function

Function SafeFloat(value, defaultVal)
    If IsNumeric(value) And Trim(value) <> "" Then
        SafeFloat = CDbl(value)
    Else
        SafeFloat = defaultVal
    End If
End Function

Function ToJSONString(val)
    Dim s
    s = CStr(val & "")
    s = Replace(s, "\", "\\")
    s = Replace(s, """", "\""")
    s = Replace(s, vbCrLf, " ")
    s = Replace(s, vbCr, " ")
    s = Replace(s, vbLf, " ")
    ToJSONString = """" & s & """"
End Function

' --------------------------------------------------------------------
' Navigation Header Component
' --------------------------------------------------------------------
Sub RenderHeader(pageTitle)
    Dim user, role, roleBadgeClass, userInitial, scriptName
    user = Session("Username")
    role = Session("Role")
    If IsNull(user) Or user = "" Then user = "Guest"
    If IsNull(role) Or role = "" Then role = "Visitor"

    userInitial = UCase(Left(user, 1))
    scriptName = LCase(Request.ServerVariables("SCRIPT_NAME"))

    If IsAdmin() Then
        roleBadgeClass = "badge-danger"
    ElseIf IsLibrarian() Then
        roleBadgeClass = "badge-info"
    Else
        roleBadgeClass = "badge-success"
    End If
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %> | BEL Library OS</title>
    <!-- Modern Next-Gen Vanilla Design System -->
    <link rel="stylesheet" href="style.asp?v=<%= Timer() %>">
    <!-- Modern Next-Gen Vanilla JavaScript Engine -->
    <script src="script.asp?v=<%= Timer() %>" defer></script>
</head>
<body>
<!-- Page Transition Veil — fades out on arrive, fades in before navigate -->
<div id="page-veil"></div>
<% If Not IsEmpty(Session("UserId")) Then %>
<div class="app-shell">
    <!-- Collapsible Left Sidebar Rail -->
    <aside id="appSidebar" class="app-sidebar">
        <!-- Sidebar Brand Header -->
        <div class="sidebar-header">
            <a href="dashboard.asp" class="sidebar-brand">
                <div class="sidebar-brand-emblem" title="Bharat Electronics Limited">
                    <img src="image.asp?file=emblem&v=4" alt="BEL" style="width:100%; height:100%; object-fit:contain; display:block;">
                </div>
                <div class="sidebar-brand-text">
                    <span class="sidebar-brand-title">BEL Library <span class="version-pill">v2.0</span></span>
                    <span class="sidebar-brand-subtitle">Bharat Electronics Ltd.</span>
                </div>
            </a>
        </div>

        <!-- Sidebar Navigation Sections -->
        <nav class="sidebar-nav">
            <!-- Workspace Group -->
            <div class="nav-section">
                <div class="nav-section-title">Workspace</div>
                <a href="dashboard.asp" class="sidebar-item <%= IIf(InStr(scriptName, "dashboard.asp") > 0, "active", "") %>">
                    <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" /></svg>
                    <span>Dashboard</span>
                </a>
            </div>

            <!-- Catalog & Media Group -->
            <div class="nav-section">
                <div class="nav-section-title">Catalog & Inventory</div>
                <% If HasPermission("books") Then %>
                    <a href="books.asp" class="sidebar-item <%= IIf(InStr(scriptName, "books.asp") > 0 Or InStr(scriptName, "books_") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" /></svg>
                        <span><%= IIf(IsStaff(), "Books Inventory", "Book Catalog") %></span>
                    </a>
                <% End If %>

                <% If HasPermission("authors") Then %>
                    <a href="authors.asp" class="sidebar-item <%= IIf(InStr(scriptName, "authors.asp") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                        <span>Authors</span>
                    </a>
                <% End If %>

                <% If HasPermission("categories") Then %>
                    <a href="categories.asp" class="sidebar-item <%= IIf(InStr(scriptName, "categories.asp") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" /></svg>
                        <span>Categories</span>
                    </a>
                <% End If %>
            </div>

            <!-- Circulation Desk Group -->
            <div class="nav-section">
                <div class="nav-section-title">Circulation Desk</div>
                <% If HasPermission("requests") Then %>
                    <a href="requests.asp" class="sidebar-item <%= IIf(InStr(scriptName, "requests.asp") > 0 Or InStr(scriptName, "request_book.asp") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
                        <span><%= IIf(IsStaff(), "Requests Pipeline", "My Reservations") %></span>
                    </a>
                <% End If %>

                <% If HasPermission("borrowings") Then %>
                    <a href="borrowings.asp" class="sidebar-item <%= IIf(InStr(scriptName, "borrowings.asp") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
                        <span><%= IIf(IsStaff(), "Active Loans", "My Borrowings") %></span>
                    </a>
                <% End If %>
            </div>

            <!-- Community & System Group -->
            <div class="nav-section">
                <div class="nav-section-title">Community & System</div>
                <% If HasPermission("feedback") Then %>
                    <a href="feedback.asp" class="sidebar-item <%= IIf(InStr(scriptName, "feedback.asp") > 0, "active", "") %>">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" /></svg>
                        <span>Feedback & Reviews</span>
                    </a>
                <% End If %>

                <% If IsAdmin() Then %>
                    <a href="manage_permissions.asp" class="sidebar-item <%= IIf(InStr(scriptName, "manage_permissions.asp") > 0, "active", "") %>" style="color:var(--warning);">
                        <svg fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" /></svg>
                        <span>Access Matrix</span>
                    </a>
                <% End If %>
            </div>
        </nav>

        <!-- Sidebar User Card Footer -->
        <div class="sidebar-footer">
            <div class="sidebar-user-card">
                <div class="user-avatar-pill"><%= userInitial %></div>
                <div class="user-details">
                    <div class="user-name-text"><%= user %></div>
                    <div class="user-role-label"><span class="badge <%= roleBadgeClass %>" style="font-size:9.5px; padding:1px 5px;"><%= role %></span></div>
                </div>
                <a href="logout.asp" class="logout-icon-btn" title="Sign Out">
                    <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                </a>
            </div>
        </div>
    </aside>

    <!-- Main Content Container with Floating Topbar -->
    <div class="app-main-content">
        <!-- Floating Command Topbar -->
        <header class="app-topbar">
            <div class="topbar-left">
                <button id="mobileSidebarToggle" class="mobile-sidebar-toggle" type="button" aria-label="Toggle Menu">
                    <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16m-7 6h7" />
                    </svg>
                </button>
                <div class="topbar-breadcrumbs">
                    <a href="dashboard.asp">BEL Library</a>
                    <span class="crumb-separator">/</span>
                    <span class="crumb-current"><%= pageTitle %></span>
                </div>
            </div>

            <!-- Global Command Palette Search Trigger -->
            <div class="topbar-center">
                <button class="cmd-palette-trigger" type="button" data-open-cmd aria-label="Open Command Palette">
                    <div class="cmd-trigger-left">
                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                        <span>Search catalog, jump to pages or actions...</span>
                    </div>
                    <kbd class="kbd-shortcut-chip">Ctrl K</kbd>
                </button>
            </div>

            <div class="topbar-right">
                <% If HasPermission("books") And IsStaff() Then %>
                    <a href="books_add.asp" class="btn btn-primary btn-sm" style="font-size:12px;">
                        <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" /></svg>
                        <span>Add Book</span>
                    </a>
                <% End If %>

                <!-- Keyboard Shortcuts HUD Button (?) -->
                <button class="icon-action-btn" type="button" onclick="document.getElementById('shortcutsModalBackdrop').classList.add('open')" title="Keyboard Shortcuts (?)">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </button>

                <!-- Theme Toggle Button -->
                <button class="icon-action-btn" type="button" data-theme-toggle title="Toggle Dark/Light Mode">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                    </svg>
                </button>
            </div>
        </header>

        <!-- Main Page Viewport Container -->
        <main class="app-container">
<% Else %>
    <!-- Guest / Login Layout Container -->
    <main style="min-height: 100vh; width: 100%;">
<% End If %>
<%
End Sub

Sub RenderFooter()
%>
    </main>
<% If Not IsEmpty(Session("UserId")) Then %>
    </div>
</div>
<% End If %>

    <!-- ====================================================================
         GLOBAL COMMAND PALETTE MODAL (Ctrl + K)
         ==================================================================== -->
    <div id="cmdPaletteBackdrop" class="cmd-palette-backdrop">
        <div class="cmd-palette-modal">
            <div class="cmd-palette-input-wrap">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <input type="text" id="cmdPaletteInput" class="cmd-palette-input" placeholder="Type a command or search books..." autocomplete="off">
                <kbd class="kbd-shortcut-chip">ESC</kbd>
            </div>
            <div id="cmdPaletteResults" class="cmd-palette-results"></div>
            <div class="cmd-palette-footer">
                <div>Navigate <kbd class="kbd-shortcut-chip">&uarr;</kbd> <kbd class="kbd-shortcut-chip">&darr;</kbd> &bull; Open <kbd class="kbd-shortcut-chip">&crarr;</kbd></div>
                <div>BEL Library Command OS</div>
            </div>
        </div>
    </div>

    <!-- ====================================================================
         SLIDE-OVER DETAIL INSPECTOR DRAWER
         ==================================================================== -->
    <div id="slideOverBackdrop" class="slide-over-backdrop">
        <div class="slide-over-drawer">
            <div class="drawer-header">
                <div id="drawerTitle" class="drawer-title">Book Details</div>
                <button id="drawerCloseBtn" class="drawer-close-btn" type="button" aria-label="Close Drawer">&times;</button>
            </div>
            <div id="drawerBody" class="drawer-body"></div>
            <div id="drawerFooter" class="drawer-footer"></div>
        </div>
    </div>

    <!-- ====================================================================
         KEYBOARD SHORTCUTS HUD CHEATSHEET MODAL (?)
         ==================================================================== -->
    <div id="shortcutsModalBackdrop" class="shortcuts-modal-backdrop">
        <div class="shortcuts-modal">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px;">
                <h3 style="font-size:18px; font-weight:800; color:var(--text-primary); display:flex; align-items:center; gap:8px;">
                    <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    Keyboard Shortcuts HUD
                </h3>
                <button id="shortcutsCloseBtn" style="background:none; border:none; color:var(--text-muted); font-size:22px; cursor:pointer;">&times;</button>
            </div>
            <p style="font-size:13px; color:var(--text-muted); margin-bottom:16px;">Power-user keyboard navigation across the BEL Library system.</p>
            <div class="shortcuts-grid">
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Open Command Palette</span>
                    <div><kbd class="kbd-shortcut-chip">Ctrl</kbd> + <kbd class="kbd-shortcut-chip">K</kbd></div>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Focus Quick Search</span>
                    <kbd class="kbd-shortcut-chip">/</kbd>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Jump to Dashboard</span>
                    <div><kbd class="kbd-shortcut-chip">G</kbd> then <kbd class="kbd-shortcut-chip">D</kbd></div>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Jump to Books Catalog</span>
                    <div><kbd class="kbd-shortcut-chip">G</kbd> then <kbd class="kbd-shortcut-chip">B</kbd></div>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Jump to Reservations</span>
                    <div><kbd class="kbd-shortcut-chip">G</kbd> then <kbd class="kbd-shortcut-chip">R</kbd></div>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Toggle Dark / Light Theme</span>
                    <kbd class="kbd-shortcut-chip">T</kbd>
                </div>
                <div class="shortcut-row">
                    <span style="font-size:13.5px; color:var(--text-primary);">Close Any Modal or Drawer</span>
                    <kbd class="kbd-shortcut-chip">ESC</kbd>
                </div>
            </div>
        </div>
    </div>

    <!-- App Toast Container -->
    <div id="toastContainer" class="toast-container"></div>
</body>
</html>
<%
End Sub
%>
