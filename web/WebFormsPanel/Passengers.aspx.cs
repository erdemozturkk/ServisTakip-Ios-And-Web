using System;
using System.Collections.Generic;
using System.Configuration;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class Passengers : Page
    {
        private static readonly string ApiBaseUrl = ConfigurationManager.AppSettings["ApiBaseUrl"];

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["AuthToken"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                RegisterAsyncTask(new System.Web.UI.PageAsyncTask(LoadPassengers));
            }
        }

        private async System.Threading.Tasks.Task LoadPassengers()
        {
            try
            {
                var passengers = await GetPassengersFromAPI();
                
                if (passengers != null && passengers.Count > 0)
                {
                    rptPassengers.DataSource = passengers;
                    rptPassengers.DataBind();
                    phNoPassengers.Visible = false;
                }
                else
                {
                    rptPassengers.DataSource = null;
                    rptPassengers.DataBind();
                    phNoPassengers.Visible = true;
                }
            }
            catch (Exception ex)
            {
                // Hata durumunda boş göster
                rptPassengers.DataSource = null;
                rptPassengers.DataBind();
                phNoPassengers.Visible = true;
                System.Diagnostics.Debug.WriteLine($"Yolcular yüklenirken hata: {ex.Message}");
            }
        }

        private async System.Threading.Tasks.Task<List<PassengerDto>> GetPassengersFromAPI()
        {
            var token = Session["AuthToken"]?.ToString();
            if (string.IsNullOrEmpty(token))
                return null;

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri(ApiBaseUrl);
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await client.GetAsync("/api/users/passengers");
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    return JsonConvert.DeserializeObject<List<PassengerDto>>(content);
                }
            }

            return null;
        }

        protected async void btnSavePassenger_Click(object sender, EventArgs e)
        {
            try
            {
                var token = Session["AuthToken"]?.ToString();
                if (string.IsNullOrEmpty(token))
                {
                    Response.Redirect("Login.aspx");
                    return;
                }

                var newPassenger = new CreatePassengerRequest
                {
                    Name = txtName.Text.Trim(),
                    Email = txtEmail.Text.Trim(),
                    PhoneNumber = txtPhoneNumber.Text.Trim(),
                    Password = "12345678", // Varsayılan şifre
                    Role = 0 // Yolcu
                };

                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri(ApiBaseUrl);
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                    var json = JsonConvert.SerializeObject(newPassenger);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    var response = await client.PostAsync("/api/users", content);
                    if (response.IsSuccessStatusCode)
                    {
                        // Başarılı - formu temizle ve listeyi yenile
                        txtName.Text = "";
                        txtEmail.Text = "";
                        txtPhoneNumber.Text = "";
                        LoadPassengers();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Yolcu eklenirken hata: {ex.Message}");
            }
        }

        public class PassengerDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string PhoneNumber { get; set; }
            public string Email { get; set; }
            public string Address { get; set; }
            public string AssignedRoute { get; set; }
            public bool IsActive { get; set; }
        }

        public class CreatePassengerRequest
        {
            public string Name { get; set; }
            public string Email { get; set; }
            public string PhoneNumber { get; set; }
            public string Password { get; set; }
            public int Role { get; set; }
        }
    }
}
