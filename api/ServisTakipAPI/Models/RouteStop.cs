using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("route_stops")]
    public class RouteStop
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("daily_route_id")]
        public int DailyRouteId { get; set; }

        [Required]
        [Column("stop_id")]
        public int StopId { get; set; }

        [Required]
        [Column("sequence_order")]
        public int SequenceOrder { get; set; }

        [Column("status")]
        public int Status { get; set; } // 0=bekliyor, 1=ulaşıldı

        [Column("estimated_arrival_time")]
        public DateTime? EstimatedArrivalTime { get; set; }

        [Column("actual_arrival_time")]
        public DateTime? ActualArrivalTime { get; set; }

        [ForeignKey("DailyRouteId")]
        public DailyRoute DailyRoute { get; set; }

        [ForeignKey("StopId")]
        public Stop Stop { get; set; }
    }
}
