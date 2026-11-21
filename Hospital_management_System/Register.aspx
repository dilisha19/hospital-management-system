<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<script runat="server">
    static string Hash(string s)
    {
        using (var sha = SHA256.Create())
            return Convert.ToBase64String(sha.ComputeHash(Encoding.UTF8.GetBytes(s)));
    }

    void Register_Click(object sender, EventArgs e)
    {
        if (txtName.Text.Trim() == "" || txtEmail.Text.Trim() == "" || txtPass.Text == "")
        { lblMsg.Text = "Fill in all three fields."; return; }
        if (txtPass.Text.Length < 6)
        { lblMsg.Text = "Use at least 6 characters for the password."; return; }

        string cs = ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString;
        try
        {
            using (var con = new SqlConnection(cs))
            {
                con.Open();
                new SqlCommand(@"IF OBJECT_ID('AppUsers') IS NULL
                    CREATE TABLE AppUsers(Id INT IDENTITY PRIMARY KEY, FullName NVARCHAR(100),
                    Email NVARCHAR(100) UNIQUE, PasswordHash NVARCHAR(200))", con).ExecuteNonQuery();

                var chk = new SqlCommand("SELECT COUNT(*) FROM AppUsers WHERE Email=@e", con);
                chk.Parameters.AddWithValue("@e", txtEmail.Text.Trim());
                if ((int)chk.ExecuteScalar() > 0) { lblMsg.Text = "That email is already registered. Log in instead."; return; }

                var cmd = new SqlCommand("INSERT INTO AppUsers(FullName,Email,PasswordHash) VALUES(@n,@e,@p)", con);
                cmd.Parameters.AddWithValue("@n", txtName.Text.Trim());
                cmd.Parameters.AddWithValue("@e", txtEmail.Text.Trim());
                cmd.Parameters.AddWithValue("@p", Hash(txtPass.Text));
                cmd.ExecuteNonQuery();
            }
            Response.Redirect("SignIn.aspx?registered=1");
        }
        catch (SqlException ex) { lblMsg.Text = "Database error: " + ex.Message; }
    }
</script>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Create account · New Hospital</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');
:root{--navy:#0A2A3B;--teal:#0E7C86;--teal-d:#0A5F67;--aqua:#6FE0D5;--bg:#EEF5F7;--line:#D5E2E6;--muted:#5A707A;--danger:#B3261E;--ok:#1E7B4F}
*{box-sizing:border-box}
body{margin:0;font-family:'Plus Jakarta Sans','Segoe UI',Arial,sans-serif;color:var(--navy);background:var(--bg)}
.shell{display:grid;grid-template-columns:1.1fr 1fr;min-height:100vh}
.brand{background:var(--navy);color:#fff;padding:44px 56px;display:flex;flex-direction:column;justify-content:space-between;gap:24px}
.logo{display:flex;align-items:center;gap:12px;font-weight:800;font-size:22px}
.logo b{width:40px;height:40px;border-radius:11px;background:var(--aqua);color:var(--navy);display:grid;place-items:center;font-size:28px;line-height:1}
.art{width:100%;max-width:520px;height:auto;align-self:center}
.pulse{width:100%;max-width:520px;height:auto;align-self:center}
.pulse path{stroke:var(--aqua);stroke-width:3;stroke-linecap:round;stroke-linejoin:round;stroke-dasharray:1;stroke-dashoffset:1;animation:draw 2.4s ease-out .2s forwards}
@keyframes draw{to{stroke-dashoffset:0}}
@media (prefers-reduced-motion:reduce){.pulse path{animation:none;stroke-dashoffset:0}}
.brand h1{font-size:50px;line-height:1.05;font-weight:800;margin:0 0 14px}
.brand p{color:#B9D3DA;max-width:40ch;line-height:1.65;margin:0 0 22px}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chips span{padding:8px 14px;border:1px solid rgba(255,255,255,.25);border-radius:999px;font-size:13px;font-weight:600;color:#DDF3F5}
.panel{display:grid;place-items:center;padding:40px 24px}
.card{width:100%;max-width:430px;background:#fff;border-radius:20px;padding:40px 36px;box-shadow:0 20px 50px rgba(10,42,59,.10)}
.card h2{font-size:28px;margin:0 0 6px;font-weight:800}
.sub{color:var(--muted);margin:0 0 26px}
.lbl{display:block;font-size:14px;font-weight:600;margin-bottom:18px}
.field{display:block;width:100%;margin-top:7px;padding:14px 14px 14px 46px;font:inherit;font-size:16px;border:1.5px solid var(--line);border-radius:12px;background:#F8FBFC no-repeat 14px center;color:var(--navy)}
.field::placeholder{color:#93A4AB}
.field:focus{outline:none;border-color:var(--teal);box-shadow:0 0 0 4px rgba(14,124,134,.15);background-color:#fff}
.i-user{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' fill='none' stroke='%230E7C86' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' viewBox='0 0 24 24'%3E%3Ccircle cx='12' cy='8' r='4'/%3E%3Cpath d='M4 21c0-4 4-6 8-6s8 2 8 6'/%3E%3C/svg%3E")}
.i-mail{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' fill='none' stroke='%230E7C86' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' viewBox='0 0 24 24'%3E%3Crect x='3' y='5' width='18' height='14' rx='2'/%3E%3Cpath d='m3 7 9 6 9-6'/%3E%3C/svg%3E")}
.i-lock{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20' fill='none' stroke='%230E7C86' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' viewBox='0 0 24 24'%3E%3Crect x='4' y='11' width='16' height='10' rx='2'/%3E%3Cpath d='M8 11V7a4 4 0 0 1 8 0v4'/%3E%3C/svg%3E")}
.pw{position:relative}
.pw .field{padding-right:74px}
.eye{position:absolute;right:8px;bottom:8px;border:0;background:none;color:var(--teal);font:inherit;font-weight:700;font-size:13px;padding:8px;border-radius:8px;cursor:pointer}
.eye:focus-visible,.btn:focus-visible,a:focus-visible{outline:3px solid var(--aqua);outline-offset:2px}
.btn{width:100%;padding:15px;border:0;border-radius:12px;background:var(--teal);color:#fff;font:inherit;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 8px 20px rgba(14,124,134,.30);transition:background .15s}
.btn:hover{background:var(--teal-d)}
.msg{display:block;min-height:22px;margin:14px 0 0;font-size:14px;color:var(--danger)}
.note{padding:12px 14px;border-radius:12px;background:#E7F5EE;color:var(--ok);font-size:14px;font-weight:600;margin-bottom:20px}
.alt{margin:18px 0 0;color:var(--muted);font-size:14px}
.alt a{color:var(--teal);font-weight:700;text-decoration:none}
.alt a:hover{text-decoration:underline}
@media (max-width:860px){.shell{grid-template-columns:1fr}.brand{padding:28px}.brand h1{font-size:32px}.art,.pulse{display:none}.card{padding:30px 22px}}
</style>
</head>
<body>
<form runat="server">
<div class="shell">
  <section class="brand">
    <div class="logo"><b>+</b> New Hospital</div>
    <svg class="art" viewBox="0 0 520 230" fill="none" aria-hidden="true">
      <rect x="0" y="200" width="520" height="3" fill="#2A5B6E"/>
      <rect x="50" y="130" width="100" height="70" rx="5" fill="#0F3A4D"/>
      <rect x="370" y="130" width="100" height="70" rx="5" fill="#0F3A4D"/>
      <rect x="140" y="70" width="240" height="130" rx="6" fill="#14566D"/>
      <rect x="236" y="14" width="48" height="48" rx="10" fill="#6FE0D5"/>
      <rect x="253" y="22" width="14" height="32" fill="#0A2A3B"/>
      <rect x="244" y="31" width="32" height="14" fill="#0A2A3B"/>
      <g fill="#6FE0D5" opacity=".85">
        <rect x="160" y="90" width="28" height="22" rx="3"/><rect x="200" y="90" width="28" height="22" rx="3"/>
        <rect x="292" y="90" width="28" height="22" rx="3"/><rect x="332" y="90" width="28" height="22" rx="3"/>
        <rect x="160" y="128" width="28" height="22" rx="3"/><rect x="200" y="128" width="28" height="22" rx="3"/>
        <rect x="292" y="128" width="28" height="22" rx="3"/><rect x="332" y="128" width="28" height="22" rx="3"/>
        <rect x="72" y="150" width="22" height="18" rx="3"/><rect x="106" y="150" width="22" height="18" rx="3"/>
        <rect x="392" y="150" width="22" height="18" rx="3"/><rect x="426" y="150" width="22" height="18" rx="3"/>
      </g>
      <rect x="238" y="156" width="44" height="44" rx="4" fill="#0A2A3B"/>
    </svg>
    <svg class="pulse" viewBox="0 0 600 70" fill="none" aria-hidden="true">
      <path pathLength="1" d="M0 36 H190 L212 36 L230 8 L254 62 L274 36 H340 L358 26 L376 36 H600"/>
    </svg>
    <div>
      <h1>Hospital Management</h1>
      <p>Create your account to book appointments and keep your visits in one place.</p>
      <div class="chips"><span>Patient records</span><span>Doctor schedules</span><span>Appointments</span></div>
    </div>
  </section>
  <section class="panel">
    <div class="card">
      <h2>Create your account</h2>
      <p class="sub">It takes less than a minute.</p>
      <label class="lbl">Full name
        <asp:TextBox ID="txtName" runat="server" CssClass="field i-user" placeholder="Your full name" autocomplete="name" />
      </label>
      <label class="lbl">Email
        <asp:TextBox ID="txtEmail" runat="server" CssClass="field i-mail" placeholder="you@example.com" autocomplete="email" />
      </label>
      <label class="lbl pw">Password
        <asp:TextBox ID="txtPass" runat="server" CssClass="field i-lock" TextMode="Password" placeholder="At least 6 characters" autocomplete="new-password" />
        <button type="button" class="eye" onclick="var i=this.parentNode.querySelector('input');i.type=i.type==='password'?'text':'password';this.textContent=i.type==='password'?'Show':'Hide'">Show</button>
      </label>
      <asp:Button Text="Create account" runat="server" CssClass="btn" OnClick="Register_Click" />
      <asp:Label ID="lblMsg" runat="server" CssClass="msg" />
      <p class="alt">Already registered? <a href="SignIn.aspx">Log in</a></p>
    </div>
  </section>
</div>
</form>
</body>
</html>