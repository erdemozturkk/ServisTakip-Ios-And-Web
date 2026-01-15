using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class Vehicles : Page
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
                    rptVehicles.DataSource = vehicles;
                    rptVehicles.DataBind();
                    phNoVehicles.Visible = false;
                }
                else
                {
                    rptVehicles.DataSource = null;
                    rptVehicles.DataBind();
                    phNoVehicles.Visible = true;
                }
            }
            catch (Exception ex)
            {
                // Hata durumunda boş liste göster
                rptVehicles.DataSource = null;
                rptVehicles.DataBind();
                phNoVehicles.Visible = true;
                System.Diagnostics.Debug.WriteLine($"Vehicle yükleme hatası: {ex.Message}");
            }
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

        protected async void btnSaveVehicle_Click(object sender, EventArgs e)
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

                    var vehicle = new
                    {
                        Plate = txtPlateNumber.Text.Trim(),
                        Model = $"{txtBrand.Text.Trim()} {txtModel.Text.Trim()}",
                        Capacity = int.Parse(txtCapacity.Text),
                        IsActive = chkIsActive.Checked,
                        DriverId = (int?)null
                    };

                    var json = JsonConvert.SerializeObject(vehicle);
                    var content = new StringContent(json, Encoding.UTF8, "application/json");

                    int vehicleId = int.Parse(hfEditVehicleId.Value);
                    HttpResponseMessage response;

                    if (vehicleId > 0)
                    {
                        // Update (PUT)
                        response = await client.PutAsync($"/api/vehicles/{vehicleId}", content);
                    }
                    else
                    {
                        // Create (POST)
                        response = await client.PostAsync("/api/vehicles", content);
                    }

                    if (response.IsSuccessStatusCode)
                    {
                        await LoadVehiclesAsync();
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
                System.Diagnostics.Debug.WriteLine($"Error saving vehicle: {ex.Message}");
            }
        }

        protected async void btnDeleteVehicle_Click(object sender, EventArgs e)
        {
            try
            {
                var token = Session["AuthToken"]?.ToString();
                if (string.IsNullOrEmpty(token))
                {
                    Response.Redirect("Login.aspx");
                    return;
                }

                int vehicleId = int.Parse(hfEditVehicleId.Value);
                if (vehicleId <= 0) return;

                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri("http://localhost:5000/");
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                    var response = await client.DeleteAsync($"/api/vehicles/{vehicleId}");
                    if (response.IsSuccessStatusCode)
                    {
                        await LoadVehiclesAsync();
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
                System.Diagnostics.Debug.WriteLine($"Error deleting vehicle: {ex.Message}");
            }
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
