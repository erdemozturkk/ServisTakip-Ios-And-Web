using System;
using System.Web;
using System.Web.Security;
using System.Web.UI;

namespace WebFormsPanel
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Check if user is authenticated
            if (Session["AuthToken"] == null && !Request.Url.AbsolutePath.Contains("Login.aspx"))
            {
                Response.Redirect("~/Login.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
            }
        }

        protected void Logout_Click(object sender, EventArgs e)
        {
            Session.Clear();
            Session.Abandon();
            FormsAuthentication.SignOut();
            Response.Redirect("~/Login.aspx", false);
            Context.ApplicationInstance.CompleteRequest();
        }

        protected string GetMenuActive(string targetPage)
        {
            var expectedPath = targetPage.StartsWith("~/", StringComparison.OrdinalIgnoreCase)
                ? targetPage
                : "~/" + targetPage;

            return string.Equals(Page.AppRelativeVirtualPath, expectedPath, StringComparison.OrdinalIgnoreCase)
                ? " active"
                : string.Empty;
        }
    }
}
