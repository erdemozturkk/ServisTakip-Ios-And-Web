using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("daily_routes")]
    public class DailyRoute
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("vehicle_id")]
        public int? VehicleId { get; set; }

        [Column("name")]
        [MaxLength(100)]
        public string Name { get; set; }

        [Required]
        [Column("route_date", TypeName = "date")]
        public DateTime RouteDate { get; set; }

        [Column("status")]
        public int Status { get; set; } // 0=planlandı, 1=başladı, 2=tamamlandı

        [Column("estimated_start_time")]
        public DateTime? EstimatedStartTime { get; set; }

        [Column("actual_start_time")]
        public DateTime? ActualStartTime { get; set; }

        [Column("estimated_end_time")]
        public DateTime? EstimatedEndTime { get; set; }

        [Column("actual_end_time")]
        public DateTime? ActualEndTime { get; set; }

        [ForeignKey("VehicleId")]
        public Vehicle Vehicle { get; set; }
    }
}
