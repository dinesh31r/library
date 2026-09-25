<%@ Language=VBScript %>
<%
Response.Buffer = True
Response.ContentType = "application/javascript"
Response.Charset = "UTF-8"
Response.Expires = -1
Response.AddHeader "Cache-Control", "no-cache, no-store, must-revalidate"
Response.AddHeader "Pragma", "no-cache"

Dim fso, f, pLogo, pRadar, pUi
Set fso = Server.CreateObject("Scripting.FileSystemObject")

pLogo = Server.MapPath("assets/js/bel-logo-data.js")
If fso.FileExists(pLogo) Then
    Set f = fso.OpenTextFile(pLogo, 1)
    Response.Write f.ReadAll & vbCrLf
    f.Close
    Set f = Nothing
End If

pRadar = Server.MapPath("assets/js/radar-pcb-engine.js")
If fso.FileExists(pRadar) Then
    Set f = fso.OpenTextFile(pRadar, 1)
    Response.Write f.ReadAll & vbCrLf
    f.Close
    Set f = Nothing
End If

pUi = Server.MapPath("assets/js/modern-ui.js")
If fso.FileExists(pUi) Then
    Set f = fso.OpenTextFile(pUi, 1)
    Response.Write f.ReadAll
    f.Close
    Set f = Nothing
End If
Set fso = Nothing
%>

