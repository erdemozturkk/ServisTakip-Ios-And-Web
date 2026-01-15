using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace ServisTakipAPI.Hubs
{
    public class LocationHub : Hub
    {
        private readonly ILocationService _locationService;
        private readonly ServisTakipDbContext _context;

        public LocationHub(ILocationService locationService, ServisTakipDbContext context)
        {
            _locationService = locationService;
            _context = context;
        }

        // Şoför kendi userId ile konum gönderir (YENİ METOD - ÖNERİLEN)
        public async Task UpdateDriverLocation(int userId, double latitude, double longitude, string status = "moving")
        {
            try
            {
                Console.WriteLine($"📍 UpdateDriverLocation called: UserId={userId}, Lat={latitude}, Lng={longitude}, Status={status}");
                
                // Bu şoföre atanmış aracı bul
                var vehicle = await _context.Vehicles
                    .Include(v => v.Driver)
                    .FirstOrDefaultAsync(v => v.DriverId == userId);
                
                if (vehicle == null)
                {
                    Console.WriteLine($"⚠️ Şoför ID {userId} için atanmış araç bulunamadı");
                    return;
                }

                Console.WriteLine($"🚗 Araç bulundu: {vehicle.Plate} (ID: {vehicle.Id})");

                var location = new VehicleLocationDto
                {
                    VehicleId = vehicle.Id,
                    Latitude = latitude,
                    Longitude = longitude,
                    Timestamp = DateTime.UtcNow,
                    Status = status ?? "moving"
                };

                Console.WriteLine($"💾 Saving to cache...");
                await _locationService.UpdateVehicleLocation(location);

                Console.WriteLine($"📡 Broadcasting to clients...");
                await Clients.All.SendAsync("ReceiveLocationUpdate", location);
                
                Console.WriteLine($"✅ UpdateDriverLocation completed successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ UpdateDriverLocation ERROR: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                throw;
            }
        }

        // Şoför konum güncellemesi gönderir (ESKİ METOD - geriye dönük uyumluluk için)
        public async Task UpdateLocation(int vehicleId, double latitude, double longitude, string status = "moving")
        {
            try
            {
                Console.WriteLine($"📍 UpdateLocation called: Vehicle={vehicleId}, Lat={latitude}, Lng={longitude}, Status={status}");
                
                var location = new VehicleLocationDto
                {
                    VehicleId = vehicleId,
                    Latitude = latitude,
                    Longitude = longitude,
                    Timestamp = DateTime.UtcNow,
                    Status = status ?? "moving" // null check
                };

                Console.WriteLine($"💾 Saving to cache...");
                // Redis cache'e kaydet
                await _locationService.UpdateVehicleLocation(location);

                Console.WriteLine($"📡 Broadcasting to clients...");
                // Tüm bağlı istemcilere bildir
                await Clients.All.SendAsync("ReceiveLocationUpdate", location);
                
                Console.WriteLine($"✅ UpdateLocation completed successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ UpdateLocation ERROR: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                throw; // Re-throw to send error to client
            }
        }

        // Rota durumu güncellemesi
        public async Task UpdateRouteStatus(int routeId, int status)
        {
            await Clients.All.SendAsync("ReceiveRouteStatusUpdate", new { routeId, status });
        }

        // Durak varış bildirimi
        public async Task NotifyStopArrival(int routeId, int stopId)
        {
            await Clients.All.SendAsync("ReceiveStopArrival", new { routeId, stopId, timestamp = DateTime.UtcNow });
        }

        // Araç offline durumuna alındı
        public async Task VehicleOffline(int vehicleId)
        {
            // Cache'ten konum bilgisini sil
            await _locationService.RemoveVehicleLocation(vehicleId);
            
            // Tüm clientlara bildir
            await Clients.All.SendAsync("VehicleOffline", vehicleId);
            Console.WriteLine($"📴 Vehicle {vehicleId} went offline");
        }

        // Belirli bir aracı takip etmek için gruba katıl
        public async Task JoinVehicleGroup(int vehicleId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"vehicle_{vehicleId}");
            Console.WriteLine($"✅ Client {Context.ConnectionId} joined vehicle group: {vehicleId}");
        }

        // Araç grubundan ayrıl
        public async Task LeaveVehicleGroup(int vehicleId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"vehicle_{vehicleId}");
            Console.WriteLine($"🚪 Client {Context.ConnectionId} left vehicle group: {vehicleId}");
        }

        // Belirli bir rotayı takip etmek için gruba katıl
        public async Task JoinRouteGroup(int routeId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"route_{routeId}");
            Console.WriteLine($"✅ Client {Context.ConnectionId} joined route group: {routeId}");
        }

        // Rota grubundan ayrıl
        public async Task LeaveRouteGroup(int routeId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"route_{routeId}");
            Console.WriteLine($"🚪 Client {Context.ConnectionId} left route group: {routeId}");
        }

        public override async Task OnConnectedAsync()
        {
            await base.OnConnectedAsync();
            Console.WriteLine($"Client connected: {Context.ConnectionId}");
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            await base.OnDisconnectedAsync(exception);
            Console.WriteLine($"Client disconnected: {Context.ConnectionId}");
        }
    }

    public class VehicleLocationDto
    {
        public int VehicleId { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public DateTime Timestamp { get; set; }
        public string Status { get; set; } = "moving"; // "moving" or "stopped"
    }

    public interface ILocationService
    {
        Task UpdateVehicleLocation(VehicleLocationDto location);
        Task<VehicleLocationDto> GetVehicleLocation(int vehicleId);
        Task RemoveVehicleLocation(int vehicleId);
    }
}
