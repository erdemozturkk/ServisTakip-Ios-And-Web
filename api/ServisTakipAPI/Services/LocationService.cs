using Microsoft.Extensions.Caching.Distributed;
using ServisTakipAPI.Hubs;
using System;
using System.Text.Json;
using System.Threading.Tasks;

namespace ServisTakipAPI.Services
{
    public class LocationService : ILocationService
    {
        private readonly IDistributedCache _cache;

        public LocationService(IDistributedCache cache)
        {
            _cache = cache;
        }

        public async Task UpdateVehicleLocation(VehicleLocationDto location)
        {
            var key = $"vehicle_location:{location.VehicleId}";
            var json = JsonSerializer.Serialize(location);
            
            var options = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
            };

            await _cache.SetStringAsync(key, json, options);
        }

        public async Task<VehicleLocationDto> GetVehicleLocation(int vehicleId)
        {
            var key = $"vehicle_location:{vehicleId}";
            var json = await _cache.GetStringAsync(key);

            if (string.IsNullOrEmpty(json))
                return null;

            return JsonSerializer.Deserialize<VehicleLocationDto>(json);
        }

        public async Task RemoveVehicleLocation(int vehicleId)
        {
            var key = $"vehicle_location:{vehicleId}";
            await _cache.RemoveAsync(key);
        }
    }
}
