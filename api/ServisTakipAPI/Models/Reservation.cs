using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("reservations")]
    public class Reservation
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("user_id")]
        public int UserId { get; set; }

        [Required]
        [Column("daily_route_id")]
        public int DailyRouteId { get; set; }

        [Required]
        [Column("status")]
        public int Status { get; set; } // 0=iptal, 1=aktif

        [ForeignKey("UserId")]
        public User User { get; set; }

        [ForeignKey("DailyRouteId")]
        public DailyRoute DailyRoute { get; set; }
    }
}
