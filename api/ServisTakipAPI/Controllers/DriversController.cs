using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Models;
using System.Text;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class DriversController : ControllerBase
    {
        private readonly ServisTakipDbContext _context;

        public DriversController(ServisTakipDbContext context)
        {
            _context = context;
        }

        // GET: api/drivers
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DriverDto>>> GetDrivers()
        {
            var drivers = await _context.Users
                .Where(u => u.Role == 1) // Role 1 = Şoför
                .Select(u => new DriverDto
                {
                    Id = u.Id,
                    Name = u.Name,
                    Email = u.Email,
                    PhoneNumber = u.PhoneNumber,
                    IsActive = true, // Users tablosunda IsActive yok, varsayılan true
                    AssignedVehicle = _context.Vehicles
                        .Where(v => v.DriverId == u.Id)
                        .Select(v => v.Plate)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(drivers);
        }

        // GET: api/drivers/5
        [HttpGet("{id}")]
        public async Task<ActionResult<DriverDto>> GetDriver(int id)
        {
            var driver = await _context.Users
                .Where(u => u.Id == id && u.Role == 1)
                .Select(u => new DriverDto
                {
                    Id = u.Id,
                    Name = u.Name,
                    Email = u.Email,
                    PhoneNumber = u.PhoneNumber,
                    IsActive = true,
                    AssignedVehicle = _context.Vehicles
                        .Where(v => v.DriverId == u.Id)
                        .Select(v => v.Plate)
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();

            if (driver == null)
            {
                return NotFound();
            }

            return Ok(driver);
        }

        // POST: api/drivers
        [HttpPost]
        public async Task<ActionResult<DriverDto>> CreateDriver([FromBody] CreateDriverRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest("Name and Email are required");
            }

            // Email'in zaten kullanılıp kullanılmadığını kontrol et
            var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (existingUser != null)
            {
                return BadRequest("Email already exists");
            }

            // Default şifre hash'i
            var passwordHash = Convert.ToBase64String(Encoding.UTF8.GetBytes("driver123"));

            var driver = new User
            {
                Name = request.Name,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                PasswordHash = passwordHash,
                Role = 1, // Şoför
                CreatedAt = DateTime.Now
            };

            _context.Users.Add(driver);
            await _context.SaveChangesAsync();

            // Araç ataması varsa yap
            if (request.VehicleId.HasValue && request.VehicleId.Value > 0)
            {
                var vehicle = await _context.Vehicles.FindAsync(request.VehicleId.Value);
                if (vehicle != null)
                {
                    // Önce başka şoförden al
                    var oldDriver = await _context.Vehicles.Where(v => v.DriverId == driver.Id).ToListAsync();
                    foreach (var v in oldDriver)
                    {
                        v.DriverId = null;
                    }
                    
                    vehicle.DriverId = driver.Id;
                    await _context.SaveChangesAsync();
                }
            }

            var driverDto = new DriverDto
            {
                Id = driver.Id,
                Name = driver.Name,
                Email = driver.Email,
                PhoneNumber = driver.PhoneNumber,
                IsActive = true,
                AssignedVehicle = request.VehicleId.HasValue ? 
                    (await _context.Vehicles.FindAsync(request.VehicleId.Value))?.Plate : null
            };

            return CreatedAtAction(nameof(GetDriver), new { id = driver.Id }, driverDto);
        }

        // PUT: api/drivers/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDriver(int id, [FromBody] UpdateDriverRequest request)
        {
            var driver = await _context.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == 1);
            if (driver == null)
            {
                return NotFound();
            }

            if (!string.IsNullOrWhiteSpace(request.Name))
                driver.Name = request.Name;
            
            if (!string.IsNullOrWhiteSpace(request.Email))
            {
                // Email değişiyorsa, başka kullanıcıda olmadığını kontrol et
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email && u.Id != id);
                if (existingUser != null)
                {
                    return BadRequest("Email already exists");
                }
                driver.Email = request.Email;
            }
            
            if (request.PhoneNumber != null)
                driver.PhoneNumber = request.PhoneNumber;

            // Araç ataması değiştiriliyorsa
            if (request.VehicleId.HasValue)
            {
                // Önce bu şoföre atanmış tüm araçları temizle
                var currentVehicles = await _context.Vehicles.Where(v => v.DriverId == id).ToListAsync();
                foreach (var v in currentVehicles)
                {
                    v.DriverId = null;
                }

                // Yeni araç ataması yap (eğer 0 değilse)
                if (request.VehicleId.Value > 0)
                {
                    var newVehicle = await _context.Vehicles.FindAsync(request.VehicleId.Value);
                    if (newVehicle != null)
                    {
                        newVehicle.DriverId = id;
                    }
                }
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/drivers/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDriver(int id)
        {
            var driver = await _context.Users.FirstOrDefaultAsync(u => u.Id == id && u.Role == 1);
            if (driver == null)
            {
                return NotFound();
            }

            // Şoföre atanmış araç varsa, önce araçtan kaldır
            var vehicles = await _context.Vehicles.Where(v => v.DriverId == id).ToListAsync();
            foreach (var vehicle in vehicles)
            {
                vehicle.DriverId = null;
            }

            _context.Users.Remove(driver);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }

    public class DriverDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public bool IsActive { get; set; }
        public string AssignedVehicle { get; set; }
    }

    public class CreateDriverRequest
    {
        public string Name { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public int? VehicleId { get; set; }
    }

    public class UpdateDriverRequest
    {
        public string Name { get; set; }
        public string Email { get; set; }
        public string PhoneNumber { get; set; }
        public int? VehicleId { get; set; }
    }
}
