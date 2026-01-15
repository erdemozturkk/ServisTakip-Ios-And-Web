using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.UI;
using System.Web.UI.WebControls;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class LiveMap : Page
    {
        private List<VehicleLocationDto> ActiveVehicles { get; set; } = new List<VehicleLocationDto>();

        protected string GoogleMapsApiKey { get; private set; } = string.Empty;
        protected string VehiclesJson { get; private set; } = "[]";

        protected async void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            GoogleMapsApiKey = ConfigurationManager.AppSettings["GoogleMapsApiKey"] ?? string.Empty;
            await LoadLiveMapData();
            BindVehicleList();
            BindStatistics();
        }

        private async Task LoadLiveMapData()
        {
            string apiBaseUrl = ConfigurationManager.AppSettings["ApiBaseUrl"] ?? string.Empty;
            string token = Session["AuthToken"]?.ToString();

            try
            {
                using (var client = new HttpClient())
                {
                    client.Timeout = TimeSpan.FromSeconds(15);

                    if (!string.IsNullOrWhiteSpace(apiBaseUrl))
                    {
                        client.BaseAddress = new Uri(apiBaseUrl);
                    }

                    if (!string.IsNullOrEmpty(token))
                    {
                        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
                    }

                    System.Diagnostics.Debug.WriteLine($"🔵 API çağrısı yapılıyor: {apiBaseUrl}/locations/active");
                    var response = await client.GetAsync("/api/locations/active");
                    System.Diagnostics.Debug.WriteLine($"📨 API yanıt kodu: {response.StatusCode}");

                    if (response.IsSuccessStatusCode)
                    {
                        var content = await response.Content.ReadAsStringAsync();
                        System.Diagnostics.Debug.WriteLine($"📦 API yanıt: {content}");
                        ActiveVehicles = JsonConvert.DeserializeObject<List<VehicleLocationDto>>(content) ?? new List<VehicleLocationDto>();
                        System.Diagnostics.Debug.WriteLine($"✅ {ActiveVehicles.Count} araç yüklendi");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"⚠️ API başarısız: {response.StatusCode}");
                        ActiveVehicles = new List<VehicleLocationDto>();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ API hatası: {ex.Message}");
                ActiveVehicles = new List<VehicleLocationDto>();
            }

            CalculateStatistics();
            VehiclesJson = JsonConvert.SerializeObject(ActiveVehicles.Select(v => new
            {
                v.Id,
                v.Latitude,
                v.Longitude,
                v.PlateNumber,
                v.RouteName,
                Status = v.Status?.ToLowerInvariant() ?? string.Empty,
                v.DriverName,
                v.PassengerCount
            }));
            
            System.Diagnostics.Debug.WriteLine($"📊 JSON oluşturuldu: {VehiclesJson.Substring(0, Math.Min(200, VehiclesJson.Length))}...");
        }

        private void BindVehicleList()
        {
            rptVehicleList.DataSource = ActiveVehicles;
            rptVehicleList.DataBind();

            phNoVehicles.Visible = ActiveVehicles.Count == 0;
            litVehiclesJson.Text = VehiclesJson;
        }

        private void BindStatistics()
        {
            lblTotalVehicles.Text = TotalVehicles.ToString();
            lblMovingVehicles.Text = MovingVehicles.ToString();
            lblStoppedVehicles.Text = StoppedVehicles.ToString();
        }

        private void CalculateStatistics()
        {
            TotalVehicles = ActiveVehicles.Count;
            MovingVehicles = ActiveVehicles.Count(v => string.Equals(v.Status, "moving", StringComparison.OrdinalIgnoreCase));
            StoppedVehicles = ActiveVehicles.Count(v => string.Equals(v.Status, "stopped", StringComparison.OrdinalIgnoreCase));
        }

        public string GetStatusBadgeClass(object statusObj)
        {
            var status = statusObj?.ToString()?.ToLowerInvariant() ?? string.Empty;
            return status == "moving" ? "vehicle-badge vehicle-badge-moving" : "vehicle-badge vehicle-badge-stopped";
        }

        public string GetStatusText(object statusObj)
        {
            var status = statusObj?.ToString()?.ToLowerInvariant() ?? string.Empty;
            return status == "moving" ? "Hareket Halinde" : "Durdu";
        }

        private int TotalVehicles { get; set; }
        private int MovingVehicles { get; set; }
        private int StoppedVehicles { get; set; }

        public class VehicleLocationDto
        {
            public int Id { get; set; }
            public string PlateNumber { get; set; } = string.Empty;
            public string RouteName { get; set; } = string.Empty;
            public string DriverName { get; set; } = string.Empty;
            public double Latitude { get; set; }
            public double Longitude { get; set; }
            public string Status { get; set; } = string.Empty;
            public int PassengerCount { get; set; }
            public DateTime LastUpdate { get; set; }
        }
    }
}
