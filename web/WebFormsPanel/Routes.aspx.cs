using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web.UI;
using Newtonsoft.Json;

namespace WebFormsPanel
{
    public partial class Routes : Page
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
                RegisterAsyncTask(new PageAsyncTask(LoadRoutesAsync));
            }
        }

        private async System.Threading.Tasks.Task LoadRoutesAsync()
        {
            try
            {
                var routes = await GetRoutesFromAPI();
                if (routes != null && routes.Count > 0)
                {
                    rptRoutes.DataSource = routes;
                    rptRoutes.DataBind();
                    phNoRoutes.Visible = false;
                }
                else
                {
                    rptRoutes.DataSource = null;
                    rptRoutes.DataBind();
                    phNoRoutes.Visible = true;
                }
            }
            catch (Exception ex)
            {
                rptRoutes.DataSource = null;
                rptRoutes.DataBind();
                phNoRoutes.Visible = true;
                System.Diagnostics.Debug.WriteLine($"Route yükleme hatası: {ex.Message}");
            }
        }

        private async System.Threading.Tasks.Task<List<RouteDto>> GetRoutesFromAPI()
        {
            var token = Session["AuthToken"]?.ToString();
            if (string.IsNullOrEmpty(token))
                return null;

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("http://localhost:5000/");
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                var response = await client.GetAsync("/api/routes");
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var apiRoutes = JsonConvert.DeserializeObject<List<ApiRouteDto>>(content);
                    
                    return apiRoutes.Select(r => new RouteDto
                    {
                        Id = r.Id,
                        Name = !string.IsNullOrEmpty(r.Name) ? r.Name : $"Rota #{r.Id}",
                        VehiclePlate = r.VehiclePlate ?? "-",
                        DriverName = r.DriverName ?? "-",
                        StartTime = r.EstimatedStartTime?.ToString("HH:mm") ?? "-",
                        EndTime = r.EstimatedEndTime?.ToString("HH:mm") ?? "-",
                        StopCount = r.StopCount,
                        IsActive = r.IsActive
                    }).ToList();
                }
            }

            return null;
        }

        protected void btnSaveRoute_Click(object sender, EventArgs e)
        {
            // Bu method artık kullanılmıyor, CreateRoute.aspx'ten direkt API'ye kaydediliyor
        }

        public class ApiRouteDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public int? VehicleId { get; set; }
            public string VehiclePlate { get; set; }
            public string DriverName { get; set; }
            public DateTime RouteDate { get; set; }
            public int Status { get; set; }
            public DateTime? EstimatedStartTime { get; set; }
            public DateTime? ActualStartTime { get; set; }
            public DateTime? EstimatedEndTime { get; set; }
            public DateTime? ActualEndTime { get; set; }
            public int StopCount { get; set; }
            public bool IsActive { get; set; }
        }

        public class RouteDto
        {
            public int Id { get; set; }
            public string Name { get; set; }
            public string VehiclePlate { get; set; }
            public string DriverName { get; set; }
            public string StartTime { get; set; }
            public string EndTime { get; set; }
            public int StopCount { get; set; }
            public bool IsActive { get; set; }
        }
    }
}
