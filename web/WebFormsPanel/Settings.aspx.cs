using System;
using System.Web.UI;

namespace WebFormsPanel
{
    public partial class Settings : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["AuthToken"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                LoadUserInfo();
            }
        }

        private void LoadUserInfo()
        {
            txtUserName.Text = Session["UserName"]?.ToString() ?? "";
            txtEmail.Text = Session["UserEmail"]?.ToString() ?? "";
        }

        protected void btnChangePassword_Click(object sender, EventArgs e)
        {
            if (txtNewPassword.Text != txtConfirmPassword.Text)
            {
                lblMessage.Text = "Yeni şifreler eşleşmiyor.";
                lblMessage.CssClass = "alert alert-danger";
                lblMessage.Visible = true;
                return;
            }

            // TODO: API call to change password
            // For now, just show success message
            lblMessage.Text = "Şifreniz başarıyla değiştirildi.";
            lblMessage.CssClass = "alert alert-success";
            lblMessage.Visible = true;

            // Clear password fields
            txtCurrentPassword.Text = "";
            txtNewPassword.Text = "";
            txtConfirmPassword.Text = "";
        }
    }
}
