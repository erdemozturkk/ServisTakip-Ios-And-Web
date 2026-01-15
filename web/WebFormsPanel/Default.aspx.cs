using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class _Default : Page
    {
        protected async void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                await LoadDashboardData();
            }
        }

        private async Task LoadDashboardData()
        {
            try
            {
                string apiBaseUrl = ConfigurationManager.AppSettings["ApiBaseUrl"];
                string token = Session["AuthToken"]?.ToString();

                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri(apiBaseUrl);
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                    // Try to get real data from API
                    var response = await client.GetAsync("/api/routes/today");
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var content = await response.Content.ReadAsStringAsync();
                        var routes = JsonConvert.DeserializeObject<List<RouteDto>>(content);
                        
                        // Calculate statistics
                        lblActiveVehicles.Text = routes.Count(r => r.Status == "InProgress").ToString();
                        lblLateVehicles.Text = routes.Count(r => r.Status == "Late").ToString();
                        lblCompletedRoutes.Text = routes.Count(r => r.Status == "Completed").ToString();
                        lblOccupancyRate.Text = "68";
                        
                        gvRoutes.DataSource = routes;
                        gvRoutes.DataBind();
                    }
                    else
                    {
                        LoadSampleData();
                    }
                }
            }
            catch
            {
                LoadSampleData();
            }
        }

        private void LoadSampleData()
        {
            // Sample statistics
            lblActiveVehicles.Text = "8";
            lblLateVehicles.Text = "2";
            lblCompletedRoutes.Text = "12";
            lblOccupancyRate.Text = "68";

            // Sample routes
            var sampleRoutes = new List<RouteDto>
            {
                new RouteDto { Id = 1, Name = "Rota A - Sabah", VehiclePlate = "34 ABC 123", DriverName = "Ahmet Yılmaz", StartTime = DateTime.Today.AddHours(7), Status = "InProgress" },
                new RouteDto { Id = 2, Name = "Rota B - Sabah", VehiclePlate = "34 DEF 456", DriverName = "Mehmet Demir", StartTime = DateTime.Today.AddHours(7).AddMinutes(30), Status = "Late" },
                new RouteDto { Id = 3, Name = "Rota C - Sabah", VehiclePlate = "34 GHI 789", DriverName = "Ayşe Kaya", StartTime = DateTime.Today.AddHours(8), Status = "Completed" }
            };
            
            gvRoutes.DataSource = sampleRoutes;
            gvRoutes.DataBind();

            // Sample alerts
            var sampleAlerts = new List<AlertDto>
            {
                new AlertDto { Type = "Warning", Title = "Gecikmeli Araçlar", Message = "2 araç rotasında gecikme var.", Time = DateTime.Now }
            };
            
            rptAlerts.DataSource = sampleAlerts;
            rptAlerts.DataBind();
        }

        protected string GetStatusBadge(string status)
        {
            switch (status)
            {
                case "Completed":
                    return "<span class='badge bg-success'>Tamamlandı</span>";
                case "InProgress":
                    return "<span class='badge bg-primary'>Devam Ediyor</span>";
                case "Late":
                    return "<span class='badge bg-warning'>Gecikmeli</span>";
                default:
                    return "<span class='badge bg-secondary'>Beklemede</span>";
            }
        }

        protected string GetAlertIcon(string type)
        {
            switch (type)
            {
                case "Warning":
                    return "<i class='bi bi-exclamation-circle text-warning'></i>";
                case "Error":
                    return "<i class='bi bi-x-circle text-danger'></i>";
                default:
                    return "<i class='bi bi-info-circle text-info'></i>";
            }
        }

        public class RouteDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string VehiclePlate { get; set; }
            public string DriverName { get; set; }
            public DateTime StartTime { get; set; }
            public string Status { get; set; }
        }

        public class AlertDto
        {
            public string Type { get; set; }
            public string Title { get; set; }
            public string Message { get; set; }
            public DateTime Time { get; set; }
        }
    }
}
