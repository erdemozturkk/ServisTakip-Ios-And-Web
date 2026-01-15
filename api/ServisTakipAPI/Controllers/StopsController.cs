using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Models;
using System.Security.Claims;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StopsController : ControllerBase
    {
        private readonly ServisTakipDbContext _context;

        public StopsController(ServisTakipDbContext context)
        {
            _context = context;
        }

        // GET: api/stops/my
        [HttpGet("my")]
        public async Task<ActionResult<IEnumerable<StopDto>>> GetMyStops()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            var stops = await _context.Stops
                .Where(s => s.UserId == userId && s.IsActive)
                .Select(s => new StopDto
                {
                    Id = s.Id,
                    Name = s.Name,
                    Latitude = (double)s.Latitude,
                    Longitude = (double)s.Longitude,
                    IsActive = s.IsActive
                })
                .ToListAsync();

            return Ok(stops);
        }

        // GET: api/stops/all (Admin için tüm duraklar)
        [HttpGet("all")]
        public async Task<ActionResult<IEnumerable<StopWithUserDto>>> GetAllStops()
        {
            // Admin kontrolü yapılabilir
            var stops = await _context.Stops
                .Include(s => s.User)
                .Where(s => s.IsActive)
                .Select(s => new StopWithUserDto
                {
                    Id = s.Id,
                    Name = s.Name,
                    Latitude = (double)s.Latitude,
                    Longitude = (double)s.Longitude,
                    IsActive = s.IsActive,
                    UserName = s.User.Name,
                    UserId = s.UserId
                })
                .ToListAsync();

            return Ok(stops);
        }

        // POST: api/stops
        [HttpPost]
        public async Task<ActionResult<StopDto>> CreateStop([FromBody] CreateStopDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            var stop = new Stop
            {
                UserId = userId,
                Name = dto.Name,
                Latitude = (decimal)dto.Latitude,
                Longitude = (decimal)dto.Longitude,
                IsActive = true
            };

            _context.Stops.Add(stop);
            await _context.SaveChangesAsync();

            var result = new StopDto
            {
                Id = stop.Id,
                Name = stop.Name,
                Latitude = (double)stop.Latitude,
                Longitude = (double)stop.Longitude,
                IsActive = stop.IsActive
            };

            return CreatedAtAction(nameof(GetStop), new { id = stop.Id }, result);
        }

        // GET: api/stops/5
        [HttpGet("{id}")]
        public async Task<ActionResult<StopDto>> GetStop(int id)
        {
            var stop = await _context.Stops.FindAsync(id);

            if (stop == null)
            {
                return NotFound();
            }

            var result = new StopDto
            {
                Id = stop.Id,
                Name = stop.Name,
                Latitude = (double)stop.Latitude,
                Longitude = (double)stop.Longitude,
                IsActive = stop.IsActive
            };

            return Ok(result);
        }

        // DELETE: api/stops/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStop(int id)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized();
            }

            var stop = await _context.Stops.FindAsync(id);
            if (stop == null)
            {
                return NotFound();
            }

            // Sadece kendi durağını silebilir
            if (stop.UserId != userId)
            {
                return Forbid();
            }

            // Durak bir rotada kullanılıyor mu kontrol et
            var isUsedInRoute = await _context.RouteStops.AnyAsync(rs => rs.StopId == id);
            if (isUsedInRoute)
            {
                return BadRequest(new { message = "Bu durak bir rotada kullanılıyor. Önce rotadan kaldırın." });
            }

            // Hard delete - veritabanından tamamen sil
            _context.Stops.Remove(stop);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }

    public class StopDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public bool IsActive { get; set; }
    }

    public class StopWithUserDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public bool IsActive { get; set; }
        public string UserName { get; set; }
        public int? UserId { get; set; }
    }

    public class CreateStopDto
    {
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
