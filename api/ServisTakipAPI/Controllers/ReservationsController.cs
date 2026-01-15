using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Data;
using ServisTakipAPI.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace ServisTakipAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ReservationsController : ControllerBase
    {
        private readonly ServisTakipDbContext _context;

        public ReservationsController(ServisTakipDbContext context)
        {
            _context = context;
        }

        // GET: api/reservations/my
        [HttpGet("my")]
        public async Task<ActionResult<IEnumerable<ReservationDto>>> GetMyReservations()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            var reservations = await _context.Reservations
                .Include(r => r.DailyRoute)
                .ThenInclude(dr => dr.Vehicle)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.DailyRoute.RouteDate)
                .Select(r => new ReservationDto
                {
                    Id = r.Id,
                    DailyRouteId = r.DailyRouteId,
                    RouteDate = r.DailyRoute.RouteDate,
                    VehiclePlate = r.DailyRoute.Vehicle.Plate,
                    Status = r.Status
                })
                .ToListAsync();

            return Ok(reservations);
        }

        // POST: api/reservations
        [HttpPost]
        public async Task<ActionResult<Reservation>> CreateReservation([FromBody] CreateReservationRequest request)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));

            // Aynı rota için zaten rezervasyon var mı kontrol et
            var existing = await _context.Reservations
                .FirstOrDefaultAsync(r => r.UserId == userId && r.DailyRouteId == request.DailyRouteId && r.Status == 1);

            if (existing != null)
                return BadRequest(new { message = "Bu rota için zaten rezervasyonunuz var" });

            var reservation = new Reservation
            {
                UserId = userId,
                DailyRouteId = request.DailyRouteId,
                Status = 1 // Aktif
            };

            _context.Reservations.Add(reservation);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetMyReservations), new { id = reservation.Id }, reservation);
        }

        // DELETE: api/reservations/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> CancelReservation(int id)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier));
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId);

            if (reservation == null)
                return NotFound();

            reservation.Status = 0; // İptal edildi
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }

    public class ReservationDto
    {
        public int Id { get; set; }
        public int DailyRouteId { get; set; }
        public DateTime RouteDate { get; set; }
        public string VehiclePlate { get; set; }
        public int Status { get; set; }
    }

    public class CreateReservationRequest
    {
        public int DailyRouteId { get; set; }
    }
}
