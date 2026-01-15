using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class Drivers : Page
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
                RegisterAsyncTask(new PageAsyncTask(LoadDriversAsync));
                RegisterAsyncTask(new PageAsyncTask(LoadVehiclesAsync));
            }
        }

        private async System.Threading.Tasks.Task LoadVehiclesAsync()
        {
            try
            {
                var vehicles = await GetVehiclesFromAPI();
                if (vehicles != null && vehicles.Count > 0)
                {
                    ddlVehicle.Items.Clear();
                    ddlVehicle.Items.Add(new System.Web.UI.WebControls.ListItem("Araç seçiniz (opsiyonel)", "0"));
                    
                    foreach (var vehicle in vehicles)
                    {
                        var displayText = $"{vehicle.Plate}";
                        if (!string.IsNullOrEmpty(vehicle.DriverName))
                        {
                            displayText += $" - {vehicle.DriverName}";
                        }
                        ddlVehicle.Items.Add(new System.Web.UI.WebControls.ListItem(displayText, vehicle.Id.ToString()));
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Araç yükleme hatası: {ex.Message}");
            }
        }

        private async System.Threading.Tasks.Task LoadDriversAsync()
        {
            try
            {
                var drivers = await GetDriversFromAPI();
                if (drivers != null && drivers.Count > 0)
                {
                    rptDrivers.DataSource = drivers;
                    rptDrivers.DataBind();
                    phNoDrivers.Visible = false;
                }
                else
                {
                    rptDrivers.DataSource = null;
                    rptDrivers.DataBind();
                    phNoDrivers.Visible = true;
                }
            }
            catch (Exception ex)
            {
                rptDrivers.DataSource = null;
                rptDrivers.DataBind();
                phNoDrivers.Visible = true;
                System.Diagnostics.Debug.WriteLine($"Driver yükleme hatası: {ex.Message}");
            }
        }

        private async System.Threading.Tasks.Task<List<DriverDto>> GetDriversFromAPI()
        {
            var token = Session["AuthToken"]?.ToString();
            if (string.IsNullOrEmpty(token))
                return null;

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("http://localhost:5000/");
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await client.GetAsync("/api/drivers");
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    return JsonConvert.DeserializeObject<List<DriverDto>>(content);
                }
            }

            return null;
        }

        private async System.Threading.Tasks.Task<List<VehicleDto>> GetVehiclesFromAPI()
        {
            var token = Session["AuthToken"]?.ToString();
            if (string.IsNullOrEmpty(token))
                return null;

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("http://localhost:5000/");
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await client.GetAsync("/api/vehicles");
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    return JsonConvert.DeserializeObject<List<VehicleDto>>(content);
                }
            }

            return null;
        }

        protected async void btnSaveDriver_Click(object sender, EventArgs e)
        {
            try
            {
                var token = Session["AuthToken"]?.ToString();
                if (string.IsNullOrEmpty(token))
                {
                    Response.Redirect("Login.aspx");
                    return;
                }

                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri("http://localhost:5000/");
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                    var driver = new
                    {
                        Name = txtName.Text.Trim(),
                        Email = txtEmail.Text.Trim(),
                        PhoneNumber = txtPhoneNumber.Text.Trim(),
                        VehicleId = int.Parse(ddlVehicle.SelectedValue)
                    };

                    var json = JsonConvert.SerializeObject(driver);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    int driverId = int.Parse(hfEditDriverId.Value);
                    HttpResponseMessage response;

                    if (driverId > 0)
                    {
                        // Update (PUT)
                        response = await client.PutAsync($"/api/drivers/{driverId}", content);
                    }
                    else
                    {
                        // Create (POST)
                        response = await client.PostAsync("/api/drivers", content);
                    }

                    if (response.IsSuccessStatusCode)
                    {
                        await LoadDriversAsync();
                    }
                    else
                    {
                        var error = await response.Content.ReadAsStringAsync();
                        System.Diagnostics.Debug.WriteLine($"API Error: {error}");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error saving driver: {ex.Message}");
            }
        }

        protected async void btnDeleteDriver_Click(object sender, EventArgs e)
        {
            try
            {
                var token = Session["AuthToken"]?.ToString();
                if (string.IsNullOrEmpty(token))
                {
                    Response.Redirect("Login.aspx");
                    return;
                }

                int driverId = int.Parse(hfEditDriverId.Value);
                if (driverId <= 0) return;

                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri("http://localhost:5000/");
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                    var response = await client.DeleteAsync($"/api/drivers/{driverId}");
                    if (response.IsSuccessStatusCode)
                    {
                        await LoadDriversAsync();
                    }
                    else
                    {
                        var error = await response.Content.ReadAsStringAsync();
                        System.Diagnostics.Debug.WriteLine($"API Error: {error}");
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error deleting driver: {ex.Message}");
            }
        }

        public class DriverDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string PhoneNumber { get; set; }
            public string Email { get; set; }
            public string AssignedVehicle { get; set; }
            public bool IsActive { get; set; }
        }

        public class VehicleDto
        {
            public int Id { get; set; }
            public string Plate { get; set; }
            public string Model { get; set; }
            public int Capacity { get; set; }
            public bool IsActive { get; set; }
            public int? DriverId { get; set; }
            public string DriverName { get; set; }
        }
    }
}
