using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Models;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class VehiclesController : ControllerBase
    {
        private readonly ServisTakipDbContext _context;

        public VehiclesController(ServisTakipDbContext context)
        {
            _context = context;
        }

        // GET: api/vehicles
        [HttpGet]
        public async Task<ActionResult<IEnumerable<VehicleDto>>> GetVehicles()
        {
            var vehicles = await _context.Vehicles
                .Include(v => v.Driver)
                .Select(v => new VehicleDto
                {
                    Id = v.Id,
                    Plate = v.Plate,
                    Model = v.Model,
                    Capacity = v.Capacity ?? 0,
                    IsActive = v.IsActive,
                    DriverId = v.DriverId,
                    DriverName = v.Driver != null ? v.Driver.Name : null
                })
                .ToListAsync();

            return Ok(vehicles);
        }

        // GET: api/vehicles/5
        [HttpGet("{id}")]
        public async Task<ActionResult<VehicleDto>> GetVehicle(int id)
        {
            var vehicle = await _context.Vehicles
                .Include(v => v.Driver)
                .Where(v => v.Id == id)
                .Select(v => new VehicleDto
                {
                    Id = v.Id,
                    Plate = v.Plate,
                    Model = v.Model,
                    Capacity = v.Capacity ?? 0,
                    IsActive = v.IsActive,
                    DriverId = v.DriverId,
                    DriverName = v.Driver != null ? v.Driver.Name : null
                })
                .FirstOrDefaultAsync();

            if (vehicle == null)
                return NotFound();

            return Ok(vehicle);
        }

        // POST: api/vehicles
        [HttpPost]
        public async Task<ActionResult<VehicleDto>> CreateVehicle([FromBody] CreateVehicleRequest request)
        {
            var vehicle = new Vehicle
            {
                Plate = request.Plate,
                Model = request.Model,
                Capacity = request.Capacity,
                IsActive = request.IsActive,
                DriverId = request.DriverId
            };

            _context.Vehicles.Add(vehicle);
            await _context.SaveChangesAsync();

            var dto = new VehicleDto
            {
                Id = vehicle.Id,
                Plate = vehicle.Plate,
                Model = vehicle.Model,
                Capacity = vehicle.Capacity ?? 0,
                IsActive = vehicle.IsActive,
                DriverId = vehicle.DriverId
            };

            return CreatedAtAction(nameof(GetVehicle), new { id = vehicle.Id }, dto);
        }

        // PUT: api/vehicles/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateVehicle(int id, [FromBody] UpdateVehicleRequest request)
        {
            var vehicle = await _context.Vehicles.FindAsync(id);
            if (vehicle == null)
                return NotFound();

            vehicle.Plate = request.Plate;
            vehicle.Model = request.Model;
            vehicle.Capacity = request.Capacity;
            vehicle.IsActive = request.IsActive;
            vehicle.DriverId = request.DriverId;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/vehicles/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteVehicle(int id)
        {
            var vehicle = await _context.Vehicles.FindAsync(id);
            if (vehicle == null)
                return NotFound();

            _context.Vehicles.Remove(vehicle);
            await _context.SaveChangesAsync();

            return NoContent();
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
        public string? DriverName { get; set; }
    }

    public class CreateVehicleRequest
    {
        public string Plate { get; set; }
        public string Model { get; set; }
        public int Capacity { get; set; }
        public bool IsActive { get; set; } = true;
        public int? DriverId { get; set; }
    }

    public class UpdateVehicleRequest
    {
        public string Plate { get; set; }
        public string Model { get; set; }
        public int Capacity { get; set; }
        public bool IsActive { get; set; }
        public int? DriverId { get; set; }
    }
}
