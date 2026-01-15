using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Apis.Auth.OAuth2;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class RoutesController : ControllerBase
    {
        private readonly ServisTakipDbContext _context;

        // TODO: Buraya kendi Google Cloud proje ID'ni yaz
        private const string GoogleProjectId = "sonorous-house-475614-n4";

        public RoutesController(ServisTakipDbContext context)
        {
            _context = context;
        }

        // GET: api/routes
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetRoutes()
        {
            var routes = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                    .ThenInclude(v => v.Driver)
                .Select(r => new
                {
                    Id = r.Id,
                    Name = r.Name,
                    VehicleId = r.VehicleId,
                    VehiclePlate = r.Vehicle != null ? r.Vehicle.Plate : null,
                    DriverName = r.Vehicle != null && r.Vehicle.Driver != null ? r.Vehicle.Driver.Name : null,
                    RouteDate = r.RouteDate,
                    Status = r.Status,
                    EstimatedStartTime = r.EstimatedStartTime,
                    ActualStartTime = r.ActualStartTime,
                    EstimatedEndTime = r.EstimatedEndTime,
                    ActualEndTime = r.ActualEndTime,
                    StopCount = _context.RouteStops.Count(rs => rs.DailyRouteId == r.Id),
                    IsActive = r.Status == 1
                })
                .OrderByDescending(r => r.RouteDate)
                .ToListAsync();

            return Ok(routes);
        }

        // GET: api/routes/5
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetRoute(int id)
        {
            var route = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                    .ThenInclude(v => v.Driver)
                .Where(r => r.Id == id)
                .Select(r => new
                {
                    Id = r.Id,
                    Name = r.Name ?? "Rota #" + r.Id,
                    VehicleId = r.VehicleId,
                    VehiclePlate = r.Vehicle != null ? r.Vehicle.Plate : null,
                    DriverName = r.Vehicle != null && r.Vehicle.Driver != null ? r.Vehicle.Driver.Name : null,
                    RouteDate = r.RouteDate,
                    Status = r.Status,
                    EstimatedStartTime = r.EstimatedStartTime,
                    ActualStartTime = r.ActualStartTime,
                    EstimatedEndTime = r.EstimatedEndTime,
                    ActualEndTime = r.ActualEndTime,
                    IsActive = r.Status == 1
                })
                .FirstOrDefaultAsync();

            if (route == null)
                return NotFound();

            return Ok(route);
        }

        // GET: api/routes/stats
        [HttpGet("stats")]
        public async Task<ActionResult<DashboardStatsDto>> GetStats()
        {
            var today = DateTime.Today;
            var todayRoutes = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                .Where(r => r.RouteDate == today)
                .ToListAsync();

            var activeVehicles = await _context.Vehicles
                .Where(v => v.IsActive)
                .CountAsync();

            var stats = new DashboardStatsDto
            {
                ActiveVehicles = todayRoutes.Count(r => r.Status == 1), // In progress
                LateVehicles = todayRoutes.Count(r => r.Status == 3), // Late
                CompletedRoutes = todayRoutes.Count(r => r.Status == 2), // Completed
                Occupancy = activeVehicles > 0 ? (todayRoutes.Count * 100) / activeVehicles : 0
            };

            return Ok(stats);
        }

        // GET: api/routes/today
        [HttpGet("today")]
        public async Task<ActionResult<IEnumerable<DailyRouteDto>>> GetTodayRoutes()
        {
            var today = DateTime.Today;
            var routes = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                .ThenInclude(v => v.Driver)
                .Where(r => r.RouteDate == today)
                .Select(r => new DailyRouteDto
                {
                    Id = r.Id,
                    VehicleId = r.VehicleId,
                    VehiclePlate = r.Vehicle != null ? r.Vehicle.Plate : null,
                    DriverName = r.Vehicle != null && r.Vehicle.Driver != null ? r.Vehicle.Driver.Name : null,
                    RouteDate = r.RouteDate,
                    Status = r.Status,
                    EstimatedStartTime = r.EstimatedStartTime,
                    ActualStartTime = r.ActualStartTime
                })
                .ToListAsync();

            return Ok(routes);
        }

        // GET: api/routes/5/stops
        [HttpGet("{id}/stops")]
        public async Task<ActionResult<IEnumerable<RouteStopDto>>> GetRouteStops(int id)
        {
            var stops = await _context.RouteStops
                .Include(rs => rs.Stop)
                .Where(rs => rs.DailyRouteId == id)
                .OrderBy(rs => rs.SequenceOrder)
                .Select(rs => new RouteStopDto
                {
                    Id = rs.Id,
                    StopId = rs.StopId,
                    StopName = rs.Stop.Name,
                    Latitude = (double)rs.Stop.Latitude,
                    Longitude = (double)rs.Stop.Longitude,
                    SequenceOrder = rs.SequenceOrder,
                    Status = rs.Status,
                    EstimatedArrivalTime = rs.EstimatedArrivalTime,
                    ActualArrivalTime = rs.ActualArrivalTime
                })
                .ToListAsync();

            return Ok(stops);
        }

        // PUT: api/routes/5/status
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateRouteStatus(int id, [FromBody] UpdateStatusRequest request)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            route.Status = request.Status;
            if (request.Status == 1 && route.ActualStartTime == null)
                route.ActualStartTime = DateTime.Now;
            else if (request.Status == 2)
                route.ActualEndTime = DateTime.Now;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/routes/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRoute(int id)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            // Önce route ile ilişkili RouteStops'ları sil
            var routeStops = await _context.RouteStops
                .Where(rs => rs.DailyRouteId == id)
                .ToListAsync();
            _context.RouteStops.RemoveRange(routeStops);

            // Route'u sil
            _context.DailyRoutes.Remove(route);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/routes/5/name
        [HttpPut("{id}/name")]
        public async Task<IActionResult> UpdateRouteName(int id, [FromBody] UpdateRouteNameRequest request)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            route.Name = request.Name;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/routes/5/update
        [HttpPut("{id}/update")]
        public async Task<IActionResult> UpdateRoute(int id, [FromBody] AdminCreateRouteRequest request)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            // Rota bilgilerini güncelle
            route.VehicleId = request.VehicleId;
            route.Name = request.Name;
            route.EstimatedStartTime = request.EstimatedStartTime;

            // Eski durakları sil
            var oldStops = await _context.RouteStops
                .Where(rs => rs.DailyRouteId == id)
                .ToListAsync();
            _context.RouteStops.RemoveRange(oldStops);

            // Yeni durakları ekle
            for (int i = 0; i < request.StopIds.Count; i++)
            {
                var routeStop = new RouteStop
                {
                    DailyRouteId = route.Id,
                    StopId = request.StopIds[i],
                    SequenceOrder = i + 1,
                    Status = 0
                };
                _context.RouteStops.Add(routeStop);
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/routes/5/start (Rotayı başlat)
        [HttpPut("{id}/start")]
        public async Task<IActionResult> StartRoute(int id)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            route.Status = 1; // In Progress
            route.ActualStartTime = DateTime.Now;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // PUT: api/routes/5/complete (Rotayı tamamla)
        [HttpPut("{id}/complete")]
        public async Task<IActionResult> CompleteRoute(int id)
        {
            var route = await _context.DailyRoutes.FindAsync(id);
            if (route == null)
                return NotFound();

            route.Status = 2; // Completed
            route.ActualEndTime = DateTime.Now;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // PUT: api/routes/stops/5/arrive
        [HttpPut("stops/{id}/arrive")]
        public async Task<IActionResult> MarkStopArrived(int id)
        {
            var stop = await _context.RouteStops.FindAsync(id);
            if (stop == null)
                return NotFound();

            stop.Status = 1;
            stop.ActualArrivalTime = DateTime.Now;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // GET: api/routes/driver/{driverId} (Şoförün rotalarını getir)
        [HttpGet("driver/{driverId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetDriverRoutes(int driverId)
        {
            var routes = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                    .ThenInclude(v => v.Driver)
                .Where(r => r.Vehicle != null && r.Vehicle.DriverId == driverId)
                .Select(r => new
                {
                    Id = r.Id,
                    Name = r.Name ?? "Rota #" + r.Id,
                    VehicleId = r.VehicleId,
                    VehiclePlate = r.Vehicle != null ? r.Vehicle.Plate : null,
                    RouteDate = r.RouteDate,
                    Status = r.Status,
                    EstimatedStartTime = r.EstimatedStartTime,
                    ActualStartTime = r.ActualStartTime,
                    EstimatedEndTime = r.EstimatedEndTime,
                    ActualEndTime = r.ActualEndTime,
                    StopCount = _context.RouteStops.Count(rs => rs.DailyRouteId == r.Id),
                    IsActive = r.Status == 1
                })
                .OrderByDescending(r => r.RouteDate)
                .ToListAsync();

            return Ok(routes);
        }

        // GET: api/routes/active (Tüm aktif rotaları getir - Yolcular için)
        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<object>>> GetActiveRoutes()
        {
            var today = DateTime.Today;
            var routes = await _context.DailyRoutes
                .Include(r => r.Vehicle)
                    .ThenInclude(v => v.Driver)
                .Where(r => r.RouteDate == today && r.Status != 2) // Tamamlanmamış rotalar
                .Select(r => new
                {
                    Id = r.Id,
                    Name = r.Name ?? "Rota #" + r.Id,
                    VehicleId = r.VehicleId,
                    VehiclePlate = r.Vehicle != null ? r.Vehicle.Plate : null,
                    DriverName = r.Vehicle != null && r.Vehicle.Driver != null ? r.Vehicle.Driver.Name : null,
                    RouteDate = r.RouteDate,
                    Status = r.Status,
                    EstimatedStartTime = r.EstimatedStartTime,
                    ActualStartTime = r.ActualStartTime,
                    EstimatedEndTime = r.EstimatedEndTime,
                    ActualEndTime = r.ActualEndTime,
                    StopCount = _context.RouteStops.Count(rs => rs.DailyRouteId == r.Id),
                    IsActive = r.Status == 1
                })
                .OrderBy(r => r.EstimatedStartTime)
                .ToListAsync();

            return Ok(routes);
        }

        // GET: api/routes/passenger/{passengerId} (Yolcunun rezervasyon yaptığı rotaları getir)
        [HttpGet("passenger/{passengerId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetPassengerRoutes(int passengerId)
        {
            var today = DateTime.Today;
            var routes = await _context.Reservations
                .Include(res => res.DailyRoute)
                    .ThenInclude(r => r.Vehicle)
                        .ThenInclude(v => v.Driver)
                .Where(res => res.UserId == passengerId && 
                             res.Status == 1 && // Aktif rezervasyon
                             res.DailyRoute.RouteDate == today &&
                             res.DailyRoute.Status != 2) // Tamamlanmamış rotalar
                .Select(res => new
                {
                    Id = res.DailyRoute.Id,
                    Name = res.DailyRoute.Name ?? "Rota #" + res.DailyRoute.Id,
                    VehicleId = res.DailyRoute.VehicleId,
                    VehiclePlate = res.DailyRoute.Vehicle != null ? res.DailyRoute.Vehicle.Plate : null,
                    DriverName = res.DailyRoute.Vehicle != null && res.DailyRoute.Vehicle.Driver != null 
                        ? res.DailyRoute.Vehicle.Driver.Name : null,
                    RouteDate = res.DailyRoute.RouteDate,
                    Status = res.DailyRoute.Status,
                    EstimatedStartTime = res.DailyRoute.EstimatedStartTime,
                    ActualStartTime = res.DailyRoute.ActualStartTime,
                    EstimatedEndTime = res.DailyRoute.EstimatedEndTime,
                    ActualEndTime = res.DailyRoute.ActualEndTime,
                    StopCount = _context.RouteStops.Count(rs => rs.DailyRouteId == res.DailyRoute.Id),
                    IsActive = res.DailyRoute.Status == 1
                })
                .OrderBy(r => r.EstimatedStartTime)
                .ToListAsync();

            return Ok(routes);
        }

        // POST: api/routes/admin/create (Admin için rota oluşturma)
        [HttpPost("admin/create")]
        public async Task<ActionResult> CreateRouteByAdmin([FromBody] AdminCreateRouteRequest request)
        {
            try
            {
                // Admin kontrolü yapılabilir
                
                // Durakların varlığını kontrol et
                var stops = await _context.Stops
                    .Where(s => request.StopIds.Contains(s.Id))
                    .ToListAsync();

                if (stops.Count != request.StopIds.Count)
                {
                    return BadRequest("Bazı duraklar bulunamadı");
                }

                // Aracın varlığını kontrol et
                var vehicle = await _context.Vehicles.FindAsync(request.VehicleId);
                if (vehicle == null)
                {
                    return BadRequest("Araç bulunamadı");
                }

                // Yeni DailyRoute oluştur
                var dailyRoute = new DailyRoute
                {
                    VehicleId = request.VehicleId,
                    Name = request.Name,
                    RouteDate = DateTime.Today,
                    Status = 0, // Planned
                    EstimatedStartTime = request.EstimatedStartTime
                };

                _context.DailyRoutes.Add(dailyRoute);
                await _context.SaveChangesAsync();

                // RouteStop'ları ekle
                for (int i = 0; i < request.StopIds.Count; i++)
                {
                    var routeStop = new RouteStop
                    {
                        DailyRouteId = dailyRoute.Id,
                        StopId = request.StopIds[i],
                        SequenceOrder = i + 1,
                        Status = 0, // Not started
                        EstimatedArrivalTime = null
                    };
                    _context.RouteStops.Add(routeStop);
                }

                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetRouteStops), new { id = dailyRoute.Id }, new { id = dailyRoute.Id, name = request.Name });
            }
            catch (Exception ex)
            {
                return BadRequest($"Rota oluşturulurken hata: {ex.Message}");
            }
        }

        // POST: api/routes/optimize - Google Cloud Fleet Routing optimizeTours
        [HttpPost("optimize")]
        [AllowAnonymous]
        public async Task<ActionResult> OptimizeRoute([FromBody] OptimizeRouteRequest request)
        {
            try
            {
                if (request.Stops == null || request.Stops.Count < 2)
                {
                    return BadRequest("En az 2 durak gerekli");
                }

                if (GoogleProjectId == "YOUR_GCP_PROJECT_ID")
                {
                    return BadRequest("RoutesController içindeki GoogleProjectId sabitini kendi proje ID'n ile güncellemelisin.");
                }

                // Google Application Default Credentials ile access token al
                // Sunucuda GOOGLE_APPLICATION_CREDENTIALS environment variable'ı ile service account JSON dosyasını işaretlemelisin.
                GoogleCredential credential = await GoogleCredential.GetApplicationDefaultAsync();
                credential = credential.CreateScoped("https://www.googleapis.com/auth/cloud-platform");
                var token = await credential.UnderlyingCredential.GetAccessTokenForRequestAsync();

                using var httpClient = new HttpClient();
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

                // Route Optimization API optimizeTours endpoint
                string url = $"https://routeoptimization.googleapis.com/v1/projects/{GoogleProjectId}:optimizeTours";

                // Zaman formatı - Google API'si için (nanos olmadan)
                var startTime = DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'");
                var endTime = DateTime.UtcNow.AddHours(4).ToString("yyyy-MM-dd'T'HH:mm:ss'Z'");

                // Shipments (her durak bir teslimat)
                var shipments = request.Stops.Select((stop, index) => new
                {
                    deliveries = new[]
                    {
                        new
                        {
                            arrivalLocation = new
                            {
                                latitude = stop.Latitude,
                                longitude = stop.Longitude
                            },
                            duration = "60s"
                        }
                    },
                    label = $"{stop.Name}_ID{stop.Id}_INDEX{index}" // Unique label
                }).ToList();

                // Tek araç tanımı - tüm durakların ortalaması başlangıç/bitiş
                var avgLat = request.Stops.Average(s => s.Latitude);
                var avgLng = request.Stops.Average(s => s.Longitude);
                
                var vehicle = new
                {
                    name = "vehicle-1",
                    startLocation = new
                    {
                        latitude = avgLat,
                        longitude = avgLng
                    },
                    endLocation = new
                    {
                        latitude = avgLat,
                        longitude = avgLng
                    },
                    costPerKilometer = 1,
                    costPerHour = 1
                };

                var body = new
                {
                    model = new
                    {
                        shipments = shipments,
                        vehicles = new[] { vehicle }
                    },
                    searchMode = "RETURN_FAST",
                    populatePolylines = false,
                    allowLargeDeadlineDespiteInterruptionRisk = false
                };

                string jsonBody = JsonSerializer.Serialize(body);
                using var content = new StringContent(jsonBody, Encoding.UTF8, "application/json");

                var response = await httpClient.PostAsync(url, content);
                var responseText = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    return BadRequest($"Google optimizeTours hatası: {response.StatusCode} - {responseText}");
                }

                // Debug: Response'u kontrol et
                Console.WriteLine("=== Google API Response ===");
                Console.WriteLine(responseText);
                Console.WriteLine("===========================");

                // Frontend doğrudan optimizeTours sonucunu bekliyor, JSON'u aynen dönüyoruz
                return Content(responseText, "application/json");
            }
            catch (Exception ex)
            {
                return BadRequest($"Optimizasyon hatası: {ex.Message}");
            }
        }

        // POST: api/routes/create
        [HttpPost("create")]
        public async Task<ActionResult> CreateRouteFromStops([FromBody] CreateRouteRequest request)
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized();
                }

                // Kullanıcının tüm durakların sahibi olup olmadığını kontrol et
                var stops = await _context.Stops
                    .Where(s => request.StopIds.Contains(s.Id))
                    .ToListAsync();

                if (stops.Count != request.StopIds.Count)
                {
                    return BadRequest("Bazı duraklar bulunamadı");
                }

                if (stops.Any(s => s.UserId != userId))
                {
                    return Forbid("Bu duraklardan bazıları size ait değil");
                }

                // Yeni DailyRoute oluştur (vehicle ve driver şimdilik null, admin panel'den atanacak)
                var dailyRoute = new DailyRoute
                {
                    VehicleId = null, // Sonra atanacak
                    RouteDate = DateTime.Today,
                    Status = 0, // Planned
                    EstimatedStartTime = null
                };

                _context.DailyRoutes.Add(dailyRoute);
                await _context.SaveChangesAsync();

                // RouteStop'ları ekle
                for (int i = 0; i < request.StopIds.Count; i++)
                {
                    var routeStop = new RouteStop
                    {
                        DailyRouteId = dailyRoute.Id,
                        StopId = request.StopIds[i],
                        SequenceOrder = i + 1,
                        Status = 0, // Not started
                        EstimatedArrivalTime = null
                    };
                    _context.RouteStops.Add(routeStop);
                }

                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetRouteStops), new { id = dailyRoute.Id }, new { id = dailyRoute.Id });
            }
            catch (Exception ex)
            {
                return BadRequest($"Rota oluşturulurken hata: {ex.Message}");
            }
        }
    }

    public class CreateRouteRequest
    {
        public string Name { get; set; }
        public List<int> StopIds { get; set; }
    }

    public class OptimizeRouteRequest
    {
        public List<StopLocation> Stops { get; set; }
    }

    public class StopLocation
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }

    public class AdminCreateRouteRequest
    {
        public string Name { get; set; }
        public int VehicleId { get; set; }
        public List<int> StopIds { get; set; }
        public DateTime? EstimatedStartTime { get; set; }
    }

    public class DashboardStatsDto
    {
        public int ActiveVehicles { get; set; }
        public int LateVehicles { get; set; }
        public int CompletedRoutes { get; set; }
        public int Occupancy { get; set; }
    }

    public class DailyRouteDto
    {
        public int Id { get; set; }
        public int? VehicleId { get; set; }
        public string? VehiclePlate { get; set; }
        public string? DriverName { get; set; }
        public DateTime RouteDate { get; set; }
        public int Status { get; set; }
        public DateTime? EstimatedStartTime { get; set; }
        public DateTime? ActualStartTime { get; set; }
    }

    public class RouteStopDto
    {
        public int Id { get; set; }
        public int StopId { get; set; }
        public string StopName { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int SequenceOrder { get; set; }
        public int Status { get; set; }
        public DateTime? EstimatedArrivalTime { get; set; }
        public DateTime? ActualArrivalTime { get; set; }
    }

    public class UpdateStatusRequest
    {
        public int Status { get; set; }
    }

    public class UpdateRouteNameRequest
    {
        public string Name { get; set; }
    }
}
