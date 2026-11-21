<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<script runat="server">
    string CS { get { return ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString; } }

    void Page_Load(object sender, EventArgs e)
    {
        if (Session["user"] == null) { Response.Redirect("SignIn.aspx"); return; }
        txtDate.Attributes["min"] = DateTime.Today.ToString("yyyy-MM-dd");
        if (!IsPostBack) { EnsureTables(); BindDropdowns(); BindList(); }
    }

    void EnsureTables()
    {
        using (var con = new SqlConnection(CS))
        {
            con.Open();
            new SqlCommand(@"
                IF OBJECT_ID('Patients') IS NULL
                  CREATE TABLE Patients(Id INT IDENTITY PRIMARY KEY, FullName NVARCHAR(100) NOT NULL,
                  Age INT, Gender NVARCHAR(10), Phone NVARCHAR(20), Problem NVARCHAR(200), CreatedOn DATETIME DEFAULT GETDATE());
                IF OBJECT_ID('Doctors') IS NULL
                  CREATE TABLE Doctors(Id INT IDENTITY PRIMARY KEY, FullName NVARCHAR(100) NOT NULL,
                  Specialty NVARCHAR(60), Phone NVARCHAR(20), Timing NVARCHAR(60), CreatedOn DATETIME DEFAULT GETDATE());
                IF OBJECT_ID('Appointments') IS NULL
                  CREATE TABLE Appointments(Id INT IDENTITY PRIMARY KEY, PatientId INT NOT NULL, DoctorId INT NOT NULL,
                  ApptAt DATETIME NOT NULL, Reason NVARCHAR(200), Status NVARCHAR(20) DEFAULT 'Booked',
                  CreatedOn DATETIME DEFAULT GETDATE());", con).ExecuteNonQuery();
        }
    }

    void BindDropdowns()
    {
        using (var con = new SqlConnection(CS))
        {
            var p = new DataTable();
            new SqlDataAdapter("SELECT Id, FullName FROM Patients ORDER BY FullName", con).Fill(p);
            ddlPatient.DataSource = p; ddlPatient.DataBind();
            ddlPatient.Items.Insert(0, new ListItem("Select a patient", ""));

            var d = new DataTable();
            new SqlDataAdapter("SELECT Id, FullName + ' (' + Specialty + ')' AS Label FROM Doctors ORDER BY FullName", con).Fill(d);
            ddlDoctor.DataSource = d; ddlDoctor.DataBind();
            ddlDoctor.Items.Insert(0, new ListItem("Select a doctor", ""));
        }
    }

    void BindList()
    {
        using (var con = new SqlConnection(CS))
        {
            var da = new SqlDataAdapter(@"SELECT a.Id, p.FullName AS Patient, d.FullName AS Doctor, d.Specialty,
                a.ApptAt, a.Reason, a.Status
                FROM Appointments a
                JOIN Patients p ON p.Id = a.PatientId
                JOIN Doctors d ON d.Id = a.DoctorId
                WHERE p.FullName LIKE @s OR d.FullName LIKE @s
                ORDER BY a.ApptAt", con);
            da.SelectCommand.Parameters.AddWithValue("@s", "%" + txtSearch.Text.Trim() + "%");
            var dt = new DataTable();
            da.Fill(dt);
            rpt.DataSource = dt;
            rpt.DataBind();
            lblCount.Text = dt.Rows.Count.ToString();
            pnlEmpty.Visible = dt.Rows.Count == 0;
        }
    }

    void Msg(string text, bool ok)
    {
        lblMsg.CssClass = ok ? "msg ok" : "msg err";
        lblMsg.Text = text;
    }

    void Book_Click(object sender, EventArgs e)
    {
        if (ddlPatient.SelectedValue == "" || ddlDoctor.SelectedValue == "")
        { Msg("Select a patient and a doctor. Add them first if the lists are empty.", false); return; }

        DateTime day, time;
        if (!DateTime.TryParse(txtDate.Text, out day) || !DateTime.TryParse(txtTime.Text, out time))
        { Msg("Pick a date and a time.", false); return; }

        DateTime at = day.Date + time.TimeOfDay;
        if (at < DateTime.Now)
        { Msg("That time has already passed. Pick a future time.", false); return; }

        using (var con = new SqlConnection(CS))
        {
            con.Open();
            var chk = new SqlCommand("SELECT COUNT(*) FROM Appointments WHERE DoctorId=@d AND ApptAt=@at", con);
            chk.Parameters.AddWithValue("@d", int.Parse(ddlDoctor.SelectedValue));
            chk.Parameters.AddWithValue("@at", at);
            if ((int)chk.ExecuteScalar() > 0)
            { Msg("This doctor is already booked at that time. Pick another slot.", false); return; }

            var cmd = new SqlCommand("INSERT INTO Appointments(PatientId,DoctorId,ApptAt,Reason) VALUES(@p,@d,@at,@r)", con);
            cmd.Parameters.AddWithValue("@p", int.Parse(ddlPatient.SelectedValue));
            cmd.Parameters.AddWithValue("@d", int.Parse(ddlDoctor.SelectedValue));
            cmd.Parameters.AddWithValue("@at", at);
            cmd.Parameters.AddWithValue("@r", txtReason.Text.Trim());
            cmd.ExecuteNonQuery();
        }
        txtReason.Text = ""; txtTime.Text = "";
        BindList();
        Msg("Appointment booked.", true);
    }

    void Search_Click(object sender, EventArgs e) { BindList(); }

    void Rpt_ItemCommand(object source, RepeaterCommandEventArgs e)
    {
        int id = Convert.ToInt32(e.CommandArgument);
        using (var con = new SqlConnection(CS))
        {
            con.Open();
            SqlCommand c = null;
            if (e.CommandName == "del") c = new SqlCommand("DELETE FROM Appointments WHERE Id=@id", con);
            else if (e.CommandName == "done") c = new SqlCommand("UPDATE Appointments SET Status='Completed' WHERE Id=@id", con);
            if (c != null) { c.Parameters.AddWithValue("@id", id); c.ExecuteNonQuery(); }
        }
        BindList();
        Msg(e.CommandName == "del" ? "Appointment cancelled." : "Marked as completed.", true);
    }

    void Logout_Click(object sender, EventArgs e) { Session.Abandon(); Response.Redirect("SignIn.aspx"); }
</script>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Appointments · New Hospital</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
:root{--navy:#0A2A3B;--teal:#0E7C86;--teal-d:#0A5F67;--aqua:#6FE0D5;--bg:#EEF5F7;--line:#D5E2E6;--muted:#5A707A;--danger:#B3261E;--ok:#1E7B4F}
*{box-sizing:border-box}
body{margin:0;font-family:'Plus Jakarta Sans','Segoe UI',Arial,sans-serif;color:var(--navy);background:var(--bg)}
.top{display:flex;justify-content:space-between;align-items:center;padding:14px 40px;background:#fff;border-bottom:1px solid var(--line)}
.logo{display:flex;align-items:center;gap:12px;font-weight:800;font-size:20px}
.logo b{width:38px;height:38px;border-radius:10px;background:var(--teal);color:#fff;display:grid;place-items:center;font-size:26px;line-height:1}
.nav{display:flex;align-items:center;gap:6px}
.nav a{padding:9px 16px;border-radius:10px;color:var(--muted);font-weight:600;font-size:14px;text-decoration:none}
.nav a:hover{background:var(--bg)}
.nav a.on{background:var(--navy);color:#fff}
.btn{padding:11px 22px;border-radius:10px;border:0;background:var(--teal);color:#fff;font:inherit;font-weight:700;font-size:15px;cursor:pointer;box-shadow:0 6px 16px rgba(14,124,134,.25)}
.btn:hover{background:var(--teal-d)}
.btn.ghost{background:#fff;color:var(--teal);border:1.5px solid var(--line);box-shadow:none}
.btn.ghost:hover{background:var(--bg)}
.btn:focus-visible,a:focus-visible,.field:focus-visible{outline:3px solid var(--aqua);outline-offset:2px}
.hero{background:var(--navy);color:#fff;padding:36px 40px 64px}
.hero h1{margin:0 0 4px;font-size:32px;font-weight:800}
.hero p{margin:0;color:#B9D3DA}
.wrap{max-width:1150px;margin:-34px auto 0;padding:0 24px 56px;display:grid;grid-template-columns:360px 1fr;gap:20px;align-items:start}
.card{background:#fff;border-radius:16px;padding:26px;box-shadow:0 10px 30px rgba(10,42,59,.08)}
.card h2{margin:0 0 18px;font-size:19px;font-weight:800}
.lbl{display:block;font-size:13px;font-weight:600;margin-bottom:14px}
.field{display:block;width:100%;margin-top:6px;padding:12px 13px;font:inherit;font-size:15px;border:1.5px solid var(--line);border-radius:10px;background:#F8FBFC;color:var(--navy)}
.field:focus{outline:none;border-color:var(--teal);box-shadow:0 0 0 4px rgba(14,124,134,.15);background:#fff}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.msg{display:block;margin-top:14px;font-size:14px;font-weight:600}
.msg.ok{color:var(--ok)}.msg.err{color:var(--danger)}
.bar{display:flex;gap:10px;margin-bottom:16px}
.bar .field{margin:0}
table{width:100%;border-collapse:collapse}
th{text-align:left;font-size:12px;color:var(--muted);font-weight:700;padding:10px 12px;border-bottom:1.5px solid var(--line)}
td{padding:13px 12px;border-bottom:1px solid var(--line);font-size:14px;vertical-align:middle}
tr:last-child td{border-bottom:0}
.name{font-weight:700}
.sm{color:var(--muted);font-size:12px}
.tag{display:inline-block;padding:3px 10px;border-radius:999px;background:#E3F3F4;color:var(--teal-d);font-size:12px;font-weight:700}
.tag.Completed{background:#E3F4EA;color:var(--ok)}
.lk{border:0;background:none;font:inherit;font-weight:700;font-size:13px;cursor:pointer;padding:6px 8px;border-radius:6px;color:var(--teal);text-decoration:none}
.lk:hover{background:var(--bg)}
.lk.del{color:var(--danger)}
.empty{text-align:center;padding:40px 10px;color:var(--muted)}
.scroll{overflow-x:auto}
@media (max-width:900px){.wrap{grid-template-columns:1fr}.top{padding:12px 16px;flex-wrap:wrap;gap:8px}.hero{padding:28px 20px 60px}}
</style>
</head>
<body>
<form runat="server">
  <header class="top">
    <div class="logo"><b>+</b> New Hospital</div>
    <nav class="nav">
      <a href="Welcome.aspx">Dashboard</a>
      <a href="Patients.aspx">Patients</a>
      <a href="Doctors.aspx">Doctors</a>
      <a href="Appointments.aspx" class="on">Appointments</a>
      <asp:LinkButton runat="server" OnClick="Logout_Click" CssClass="btn ghost" style="padding:9px 16px;font-size:14px;margin-left:8px">Log out</asp:LinkButton>
    </nav>
  </header>
  <section class="hero">
    <h1>Appointments</h1>
    <p>Hospital Management · <asp:Label ID="lblCount" runat="server" /> appointments</p>
  </section>

  <div class="wrap">
    <div class="card">
      <h2>Book an appointment</h2>
      <label class="lbl">Patient
        <asp:DropDownList ID="ddlPatient" runat="server" CssClass="field" DataTextField="FullName" DataValueField="Id" />
      </label>
      <label class="lbl">Doctor
        <asp:DropDownList ID="ddlDoctor" runat="server" CssClass="field" DataTextField="Label" DataValueField="Id" />
      </label>
      <div class="row2">
        <label class="lbl">Date
          <asp:TextBox ID="txtDate" runat="server" CssClass="field" TextMode="Date" />
        </label>
        <label class="lbl">Time
          <asp:TextBox ID="txtTime" runat="server" CssClass="field" TextMode="Time" />
        </label>
      </div>
      <label class="lbl">Reason
        <asp:TextBox ID="txtReason" runat="server" CssClass="field" MaxLength="200" placeholder="Reason for visit" />
      </label>
      <asp:Button runat="server" Text="Book appointment" CssClass="btn" OnClick="Book_Click" />
      <asp:Label ID="lblMsg" runat="server" CssClass="msg" />
    </div>

    <div class="card">
      <div class="bar">
        <asp:TextBox ID="txtSearch" runat="server" CssClass="field" placeholder="Search by patient or doctor" />
        <asp:Button runat="server" Text="Search" CssClass="btn" OnClick="Search_Click" />
      </div>
      <div class="scroll">
      <table>
        <thead><tr><th>When</th><th>Patient</th><th>Doctor</th><th>Status</th><th></th></tr></thead>
        <tbody>
        <asp:Repeater ID="rpt" runat="server" OnItemCommand="Rpt_ItemCommand">
          <ItemTemplate>
            <tr>
              <td><div class="name"><%# Eval("ApptAt", "{0:dd MMM yyyy}") %></div><div class="sm"><%# Eval("ApptAt", "{0:hh:mm tt}") %></div></td>
              <td><div class="name"><%#: Eval("Patient") %></div><div class="sm"><%#: Eval("Reason") %></div></td>
              <td><div class="name"><%#: Eval("Doctor") %></div><div class="sm"><%#: Eval("Specialty") %></div></td>
              <td><span class="tag <%#: Eval("Status") %>"><%#: Eval("Status") %></span></td>
              <td style="white-space:nowrap">
                <asp:LinkButton runat="server" CommandName="done" CommandArgument='<%# Eval("Id") %>' CssClass="lk">Done</asp:LinkButton>
                <asp:LinkButton runat="server" CommandName="del" CommandArgument='<%# Eval("Id") %>' CssClass="lk del" OnClientClick="return confirm('Cancel this appointment?');">Cancel</asp:LinkButton>
              </td>
            </tr>
          </ItemTemplate>
        </asp:Repeater>
        </tbody>
      </table>
      </div>
      <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty" Visible="false">No appointments yet. Book the first one using the form.</asp:Panel>
    </div>
  </div>
</form>
</body>
</html>