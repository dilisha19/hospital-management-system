<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<script runat="server">
    string CS { get { return ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString; } }

    void Page_Load(object sender, EventArgs e)
    {
        if (Session["user"] == null) { Response.Redirect("SignIn.aspx"); return; }
        if (!IsPostBack) { EnsureTable(); BindList(); }
    }

    void EnsureTable()
    {
        using (var con = new SqlConnection(CS))
        {
            con.Open();
            new SqlCommand(@"IF OBJECT_ID('Patients') IS NULL
                CREATE TABLE Patients(Id INT IDENTITY PRIMARY KEY, FullName NVARCHAR(100) NOT NULL,
                Age INT, Gender NVARCHAR(10), Phone NVARCHAR(20), Problem NVARCHAR(200),
                CreatedOn DATETIME DEFAULT GETDATE())", con).ExecuteNonQuery();
        }
    }

    void BindList()
    {
        using (var con = new SqlConnection(CS))
        {
            var da = new SqlDataAdapter(@"SELECT Id, FullName, Age, Gender, Phone, Problem FROM Patients
                WHERE FullName LIKE @s OR Phone LIKE @s ORDER BY Id DESC", con);
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

    void ClearForm()
    {
        txtName.Text = ""; txtAge.Text = ""; txtPhone.Text = ""; txtProblem.Text = "";
        ddlGender.SelectedIndex = 0;
        ViewState["id"] = null;
        btnSave.Text = "Add patient";
        btnCancel.Visible = false;
        formTitle.InnerText = "Add a patient";
    }

    void Save_Click(object sender, EventArgs e)
    {
        int age;
        if (txtName.Text.Trim() == "" || !int.TryParse(txtAge.Text, out age) || age < 0 || age > 120)
        { Msg("Enter a name and an age between 0 and 120.", false); return; }

        using (var con = new SqlConnection(CS))
        {
            con.Open();
            SqlCommand cmd;
            if (ViewState["id"] == null)
                cmd = new SqlCommand("INSERT INTO Patients(FullName,Age,Gender,Phone,Problem) VALUES(@n,@a,@g,@p,@pr)", con);
            else
            {
                cmd = new SqlCommand("UPDATE Patients SET FullName=@n,Age=@a,Gender=@g,Phone=@p,Problem=@pr WHERE Id=@id", con);
                cmd.Parameters.AddWithValue("@id", (int)ViewState["id"]);
            }
            cmd.Parameters.AddWithValue("@n", txtName.Text.Trim());
            cmd.Parameters.AddWithValue("@a", age);
            cmd.Parameters.AddWithValue("@g", ddlGender.SelectedValue);
            cmd.Parameters.AddWithValue("@p", txtPhone.Text.Trim());
            cmd.Parameters.AddWithValue("@pr", txtProblem.Text.Trim());
            cmd.ExecuteNonQuery();
        }
        bool wasEdit = ViewState["id"] != null;
        ClearForm();
        BindList();
        Msg(wasEdit ? "Patient updated." : "Patient added.", true);
    }

    void Cancel_Click(object sender, EventArgs e) { ClearForm(); lblMsg.Text = ""; }
    void Search_Click(object sender, EventArgs e) { BindList(); }

    void Rpt_ItemCommand(object source, RepeaterCommandEventArgs e)
    {
        int id = Convert.ToInt32(e.CommandArgument);
        using (var con = new SqlConnection(CS))
        {
            con.Open();
            if (e.CommandName == "del")
            {
                var d = new SqlCommand("DELETE FROM Patients WHERE Id=@id", con);
                d.Parameters.AddWithValue("@id", id);
                d.ExecuteNonQuery();
                BindList();
                Msg("Patient deleted.", true);
            }
            else if (e.CommandName == "edit")
            {
                var c = new SqlCommand("SELECT FullName,Age,Gender,Phone,Problem FROM Patients WHERE Id=@id", con);
                c.Parameters.AddWithValue("@id", id);
                using (var r = c.ExecuteReader())
                {
                    if (r.Read())
                    {
                        txtName.Text = r["FullName"].ToString();
                        txtAge.Text = r["Age"].ToString();
                        ddlGender.SelectedValue = r["Gender"].ToString();
                        txtPhone.Text = r["Phone"].ToString();
                        txtProblem.Text = r["Problem"].ToString();
                        ViewState["id"] = id;
                        btnSave.Text = "Save changes";
                        btnCancel.Visible = true;
                        formTitle.InnerText = "Edit patient";
                        lblMsg.Text = "";
                    }
                }
            }
        }
    }

    void Logout_Click(object sender, EventArgs e) { Session.Abandon(); Response.Redirect("SignIn.aspx"); }
</script>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Patients · New Hospital</title>
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
.wrap{max-width:1100px;margin:-34px auto 0;padding:0 24px 56px;display:grid;grid-template-columns:360px 1fr;gap:20px;align-items:start}
.card{background:#fff;border-radius:16px;padding:26px;box-shadow:0 10px 30px rgba(10,42,59,.08)}
.card h2{margin:0 0 18px;font-size:19px;font-weight:800}
.lbl{display:block;font-size:13px;font-weight:600;margin-bottom:14px}
.field{display:block;width:100%;margin-top:6px;padding:12px 13px;font:inherit;font-size:15px;border:1.5px solid var(--line);border-radius:10px;background:#F8FBFC;color:var(--navy)}
.field:focus{outline:none;border-color:var(--teal);box-shadow:0 0 0 4px rgba(14,124,134,.15);background:#fff}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.actions{display:flex;gap:10px;margin-top:4px}
.msg{display:block;margin-top:14px;font-size:14px;font-weight:600}
.msg.ok{color:var(--ok)}.msg.err{color:var(--danger)}
.bar{display:flex;gap:10px;margin-bottom:16px}
.bar .field{margin:0}
table{width:100%;border-collapse:collapse}
th{text-align:left;font-size:12px;color:var(--muted);font-weight:700;padding:10px 12px;border-bottom:1.5px solid var(--line)}
td{padding:13px 12px;border-bottom:1px solid var(--line);font-size:14px;vertical-align:middle}
tr:last-child td{border-bottom:0}
.name{font-weight:700}
.tag{display:inline-block;padding:3px 10px;border-radius:999px;background:#E3F3F4;color:var(--teal-d);font-size:12px;font-weight:700}
.lk{border:0;background:none;font:inherit;font-weight:700;font-size:13px;cursor:pointer;padding:6px 8px;border-radius:6px;color:var(--teal);text-decoration:none}
.lk:hover{background:var(--bg)}
.lk.del{color:var(--danger)}
.empty{text-align:center;padding:40px 10px;color:var(--muted)}
.scroll{overflow-x:auto}
@media (max-width:900px){.wrap{grid-template-columns:1fr}.top{padding:12px 16px}.hero{padding:28px 20px 60px}}
</style>
</head>
<body>
<form runat="server">
  <header class="top">
    <div class="logo"><b>+</b> New Hospital</div>
    <nav class="nav">
      <a href="Welcome.aspx">Dashboard</a>
      <a href="Patients.aspx" class="on">Patients</a>
      <asp:LinkButton runat="server" OnClick="Logout_Click" CssClass="btn ghost" style="padding:9px 16px;font-size:14px;margin-left:8px">Log out</asp:LinkButton>
    </nav>
  </header>
  <section class="hero">
    <h1>Patients</h1>
    <p>Hospital Management · <asp:Label ID="lblCount" runat="server" /> patients on record</p>
  </section>

  <div class="wrap">
    <div class="card">
      <h2 id="formTitle" runat="server">Add a patient</h2>
      <label class="lbl">Full name
        <asp:TextBox ID="txtName" runat="server" CssClass="field" MaxLength="100" placeholder="Patient name" />
      </label>
      <div class="row2">
        <label class="lbl">Age
          <asp:TextBox ID="txtAge" runat="server" CssClass="field" TextMode="Number" placeholder="e.g. 34" />
        </label>
        <label class="lbl">Gender
          <asp:DropDownList ID="ddlGender" runat="server" CssClass="field">
            <asp:ListItem>Male</asp:ListItem><asp:ListItem>Female</asp:ListItem><asp:ListItem>Other</asp:ListItem>
          </asp:DropDownList>
        </label>
      </div>
      <label class="lbl">Phone
        <asp:TextBox ID="txtPhone" runat="server" CssClass="field" MaxLength="20" placeholder="Mobile number" />
      </label>
      <label class="lbl">Problem
        <asp:TextBox ID="txtProblem" runat="server" CssClass="field" MaxLength="200" placeholder="Reason for visit" />
      </label>
      <div class="actions">
        <asp:Button ID="btnSave" runat="server" Text="Add patient" CssClass="btn" OnClick="Save_Click" />
        <asp:Button ID="btnCancel" runat="server" Text="Cancel" CssClass="btn ghost" OnClick="Cancel_Click" Visible="false" />
      </div>
      <asp:Label ID="lblMsg" runat="server" CssClass="msg" />
    </div>

    <div class="card">
      <div class="bar">
        <asp:TextBox ID="txtSearch" runat="server" CssClass="field" placeholder="Search by name or phone" />
        <asp:Button runat="server" Text="Search" CssClass="btn" OnClick="Search_Click" />
      </div>
      <div class="scroll">
      <table>
        <thead><tr><th>Patient</th><th>Age</th><th>Phone</th><th>Problem</th><th></th></tr></thead>
        <tbody>
        <asp:Repeater ID="rpt" runat="server" OnItemCommand="Rpt_ItemCommand">
          <ItemTemplate>
            <tr>
              <td><div class="name"><%#: Eval("FullName") %></div><span class="tag"><%#: Eval("Gender") %></span></td>
              <td><%#: Eval("Age") %></td>
              <td><%#: Eval("Phone") %></td>
              <td><%#: Eval("Problem") %></td>
              <td style="white-space:nowrap">
                <asp:LinkButton runat="server" CommandName="edit" CommandArgument='<%# Eval("Id") %>' CssClass="lk">Edit</asp:LinkButton>
                <asp:LinkButton runat="server" CommandName="del" CommandArgument='<%# Eval("Id") %>' CssClass="lk del" OnClientClick="return confirm('Delete this patient?');">Delete</asp:LinkButton>
              </td>
            </tr>
          </ItemTemplate>
        </asp:Repeater>
        </tbody>
      </table>
      </div>
      <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty" Visible="false">No patients yet. Add the first one using the form.</asp:Panel>
    </div>
  </div>
</form>
</body>
</html>