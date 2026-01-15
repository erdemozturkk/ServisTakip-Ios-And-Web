using System;
using System.Configuration;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class Login : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Check if already logged in
                if (Session["AuthToken"] != null)
                {
                    Response.Redirect("~/Default.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                }
            }
        }

        protected async void BtnLogin_Click(object sender, EventArgs e)
        {
            try
            {
                string apiBaseUrl = ConfigurationManager.AppSettings["ApiBaseUrl"];
                
                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri(apiBaseUrl);
                    
                    var loginData = new
                    {
                        email = txtEmail.Text,
                        password = txtPassword.Text
                    };
                    
                    var json = JsonConvert.SerializeObject(loginData);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");
                    
                    var response = await client.PostAsync("/api/auth/login", content);
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var responseContent = await response.Content.ReadAsStringAsync();
                        var loginResponse = JsonConvert.DeserializeObject<LoginResponse>(responseContent);
                        
                        // Check if user is admin (Role = 2)
                        if (loginResponse.User.Role != 2)
                        {
                            ShowError("Bu panele sadece yöneticiler giriş yapabilir.");
                            return;
                        }
                        
                        // Save to session
                        Session["AuthToken"] = loginResponse.Token;
                        Session["UserName"] = loginResponse.User.Name;
                        Session["UserEmail"] = loginResponse.User.Email;
                        Session["UserRole"] = loginResponse.User.Role;
                        
                        // Set authentication cookie
                        FormsAuthentication.SetAuthCookie(loginResponse.User.Email, false);
                        
                        // Redirect to dashboard
                        Response.Redirect("~/Default.aspx", false);
                        Context.ApplicationInstance.CompleteRequest();
                    }
                    else
                    {
                        ShowError("Email veya şifre hatalı.");
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError($"Giriş yapılırken bir hata oluştu: {ex.Message}");
            }
        }

        private void ShowError(string message)
        {
            lblError.Text = message;
            pnlError.Visible = true;
        }

        private class LoginResponse
        {
            public string Token { get; set; }
            public UserDto User { get; set; }
        }

        private class UserDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string Email { get; set; }
            public string PhoneNumber { get; set; }
            public int Role { get; set; }
        }
    }
}
