using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Hubs;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LocationsController : ControllerBase
    {
        private readonly ILocationService _locationService;
        private readonly ServisTakipDbContext _context;

        public LocationsController(ILocationService locationService, ServisTakipDbContext context)
        {
            _locationService = locationService;
            _context = context;
        }

        // GET: api/locations/5
        [HttpGet("{vehicleId}")]
        public async Task<ActionResult<VehicleLocationDto>> GetVehicleLocation(int vehicleId)
        {
            var location = await _locationService.GetVehicleLocation(vehicleId);
            
            if (location == null)
                return NotFound(new { message = "Araç konumu bulunamadı" });

            return Ok(location);
        }

        // GET: api/locations/active
        [HttpGet("active")]
        public async Task<ActionResult<List<ActiveVehicleDto>>> GetActiveVehicles()
        {
            var activeVehicles = new List<ActiveVehicleDto>();

            // Veritabanından tüm aktif araçları al
            var vehicles = await _context.Vehicles
                .Include(v => v.Driver)
                .Where(v => v.IsActive)
                .ToListAsync();

            // Her araç için cache'ten konum bilgisini kontrol et
            foreach (var vehicle in vehicles)
            {
                var location = await _locationService.GetVehicleLocation(vehicle.Id);
                
                if (location != null)
                {
                    // Son 10 dakika içinde konum güncellemesi varsa aktif kabul et
                    if ((System.DateTime.UtcNow - location.Timestamp).TotalMinutes <= 10)
                    {
                        activeVehicles.Add(new ActiveVehicleDto
                        {
                            Id = vehicle.Id,
                            PlateNumber = vehicle.Plate,
                            Latitude = location.Latitude,
                            Longitude = location.Longitude,
                            RouteName = "Aktif Rota", // TODO: DailyRoutes tablosundan çek
                            Status = location.Status ?? "moving",
                            DriverName = vehicle.Driver?.Name ?? "Bilinmiyor",
                            PassengerCount = 0, // TODO: Reservations tablosundan hesapla
                            LastUpdate = location.Timestamp
                        });
                    }
                }
            }

            return Ok(activeVehicles);
        }
    }

    public class ActiveVehicleDto
    {
        public int Id { get; set; }
        public string PlateNumber { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string RouteName { get; set; }
        public string Status { get; set; }
        public string DriverName { get; set; }
        public int PassengerCount { get; set; }
        public System.DateTime LastUpdate { get; set; }
    }
}
