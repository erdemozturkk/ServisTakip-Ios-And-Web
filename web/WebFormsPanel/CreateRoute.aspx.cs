using System;
using System.Web.UI;

namespace WebFormsPanel
{
    public partial class CreateRoute : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Admin kontrolü yapılabilir
            if (Session["UserRole"] == null || Session["UserRole"].ToString() != "2")
            {
                Response.Redirect("Login.aspx");
            }
        }
    }
}
