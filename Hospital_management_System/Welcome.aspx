<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<script runat="server">
    int Count(SqlConnection con, string sql)
    {
        try { return (int)new SqlCommand(sql, con).ExecuteScalar(); }
        catch { return 0; }
    }

    void Page_Load(object sender, EventArgs e)
    {
        if (Session["user"] == null) { Response.Redirect("SignIn.aspx"); return; }
        lblUser.Text = Server.HtmlEncode(Session["user"].ToString());
        lblDate.Text = DateTime.Now.ToString("dddd, dd MMMM yyyy");
        try
        {
            string cs = ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString;
            using (var con = new SqlConnection(cs))
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
                lblPatients.Text = Count(con, "SELECT COUNT(*) FROM Patients").ToString();
                lblDoctors.Text = Count(con, "SELECT COUNT(*) FROM Doctors").ToString();
                lblToday.Text = Count(con, "SELECT COUNT(*) FROM Appointments WHERE CAST(ApptAt AS DATE)=CAST(GETDATE() AS DATE)").ToString();
                lblTotal.Text = Count(con, "SELECT COUNT(*) FROM Appointments").ToString();

                var dt = new DataTable();
                new SqlDataAdapter(@"SELECT TOP 6 a.ApptAt, p.FullName AS Patient, d.FullName AS Doctor, d.Specialty, a.Status
                    FROM Appointments a
                    JOIN Patients p ON p.Id = a.PatientId
                    JOIN Doctors d ON d.Id = a.DoctorId
                    WHERE a.ApptAt >= CAST(GETDATE() AS DATE) AND a.Status <> 'Completed'
                    ORDER BY a.ApptAt", con).Fill(dt);
                rpt.DataSource = dt;
                rpt.DataBind();
                pnlEmpty.Visible = dt.Rows.Count == 0;
            }
        }
        catch (Exception ex)
        {
            lblPatients.Text = lblDoctors.Text = lblToday.Text = lblTotal.Text = "-";
            pnlEmpty.Visible = true;
            lblErr.Text = ex.Message;
        }
    }

    void Logout_Click(object sender, EventArgs e)
    {
        Session.Abandon();
        Response.Redirect("SignIn.aspx");
    }
</script>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Dashboard · New Hospital</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
:root{--navy:#0A2A3B;--teal:#0E7C86;--teal-d:#0A5F67;--aqua:#6FE0D5;--bg:#EEF5F7;--line:#D5E2E6;--muted:#5A707A;--ok:#1E7B4F}
*{box-sizing:border-box}
body{margin:0;font-family:'Plus Jakarta Sans','Segoe UI',Arial,sans-serif;color:var(--navy);background:var(--bg)}
.top{display:flex;justify-content:space-between;align-items:center;padding:14px 40px;background:#fff;border-bottom:1px solid var(--line)}
.logo{display:flex;align-items:center;gap:12px;font-weight:800;font-size:20px}
.logo b{width:38px;height:38px;border-radius:10px;background:var(--teal);color:#fff;display:grid;place-items:center;font-size:26px;line-height:1}
.nav{display:flex;align-items:center;gap:6px}
.nav a{padding:9px 16px;border-radius:10px;color:var(--muted);font-weight:600;font-size:14px;text-decoration:none}
.nav a:hover{background:var(--bg)}
.nav a.on{background:var(--navy);color:#fff}
.btn{padding:9px 16px;border-radius:10px;border:1.5px solid var(--line);background:#fff;color:var(--teal);font:inherit;font-weight:700;font-size:14px;cursor:pointer;margin-left:8px;text-decoration:none}
.btn:hover{background:var(--bg)}
.btn:focus-visible,a:focus-visible{outline:3px solid var(--aqua);outline-offset:2px}
.hero{background:var(--navy);color:#fff;padding:48px 40px 78px}
.hero small{display:block;color:var(--aqua);font-weight:700;font-size:15px;margin-bottom:8px}
.hero h2{margin:0 0 6px;font-size:38px;font-weight:800}
.hero p{margin:0;color:#B9D3DA}
.main{max-width:1050px;margin:-44px auto 0;padding:0 24px 56px}
.tiles{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:16px}
.tile{display:block;background:#fff;border-radius:16px;padding:22px 24px;box-shadow:0 10px 30px rgba(10,42,59,.08);text-decoration:none;color:inherit}
a.tile:hover{box-shadow:0 14px 34px rgba(10,42,59,.16)}
.tile span{color:var(--muted);font-size:14px;font-weight:600}
.tile strong{display:block;font-size:40px;font-weight:800;margin-top:6px;color:var(--teal)}
.panel{background:#fff;border-radius:16px;padding:26px;margin-top:20px;box-shadow:0 10px 30px rgba(10,42,59,.08)}
.panel-h{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.panel-h h3{margin:0;font-size:19px;font-weight:800}
.panel-h a{color:var(--teal);font-weight:700;font-size:14px;text-decoration:none}
.panel-h a:hover{text-decoration:underline}
table{width:100%;border-collapse:collapse}
th{text-align:left;font-size:12px;color:var(--muted);font-weight:700;padding:10px 12px;border-bottom:1.5px solid var(--line)}
td{padding:13px 12px;border-bottom:1px solid var(--line);font-size:14px;vertical-align:middle}
tr:last-child td{border-bottom:0}
.name{font-weight:700}
.sm{color:var(--muted);font-size:12px}
.tag{display:inline-block;padding:3px 10px;border-radius:999px;background:#E3F3F4;color:var(--teal-d);font-size:12px;font-weight:700}
.empty{text-align:center;padding:34px 10px;color:var(--muted)}
.scroll{overflow-x:auto}
@media (max-width:760px){.top{padding:12px 16px;flex-wrap:wrap;gap:8px}.hero{padding:34px 20px 70px}.hero h2{font-size:28px}}
</style>
</head>
<body>
<form runat="server">
  <header class="top">
    <div class="logo"><b>+</b> New Hospital</div>
    <nav class="nav">
      <a href="Welcome.aspx" class="on">Dashboard</a>
      <a href="Patients.aspx">Patients</a>
      <a href="Doctors.aspx">Doctors</a>
      <a href="Appointments.aspx">Appointments</a>
      <asp:LinkButton runat="server" OnClick="Logout_Click" CssClass="btn">Log out</asp:LinkButton>
    </nav>
  </header>
  <section class="hero">
    <small>Hospital Management</small>
    <h2>Hello, <asp:Label ID="lblUser" runat="server" />.</h2>
    <p><asp:Label ID="lblDate" runat="server" /></p>
  </section>
  <main class="main">
    <div class="tiles">
      <a class="tile" href="Patients.aspx"><span>Patients</span><strong><asp:Label ID="lblPatients" runat="server" /></strong></a>
      <a class="tile" href="Doctors.aspx"><span>Doctors</span><strong><asp:Label ID="lblDoctors" runat="server" /></strong></a>
      <a class="tile" href="Appointments.aspx"><span>Appointments today</span><strong><asp:Label ID="lblToday" runat="server" /></strong></a>
      <a class="tile" href="Appointments.aspx"><span>All appointments</span><strong><asp:Label ID="lblTotal" runat="server" /></strong></a>
    </div>

    <div class="panel">
      <div class="panel-h"><h3>Upcoming appointments</h3><a href="Appointments.aspx">View all</a></div>
      <asp:Label ID="lblErr" runat="server" ForeColor="Red" />
      <div class="scroll">
      <table>
        <thead><tr><th>When</th><th>Patient</th><th>Doctor</th><th>Status</th></tr></thead>
        <tbody>
        <asp:Repeater ID="rpt" runat="server">
          <ItemTemplate>
            <tr>
              <td><div class="name"><%# Eval("ApptAt", "{0:dd MMM yyyy}") %></div><div class="sm"><%# Eval("ApptAt", "{0:hh:mm tt}") %></div></td>
              <td class="name"><%#: Eval("Patient") %></td>
              <td><div class="name"><%#: Eval("Doctor") %></div><div class="sm"><%#: Eval("Specialty") %></div></td>
              <td><span class="tag"><%#: Eval("Status") %></span></td>
            </tr>
          </ItemTemplate>
        </asp:Repeater>
        </tbody>
      </table>
      </div>
      <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty" Visible="false">No upcoming appointments. Book one from the Appointments page.</asp:Panel>
    </div>
  </main>
</form>
</body>
</html>