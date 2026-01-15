using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("vehicle_locations")]
    public class VehicleLocation
    {
        [Key]
        [Column("id")]
        public long Id { get; set; }

        [Required]
        [Column("vehicle_id")]
        public int VehicleId { get; set; }

        [Required]
        [Column("latitude", TypeName = "decimal(9,6)")]
        public decimal Latitude { get; set; }

        [Required]
        [Column("longitude", TypeName = "decimal(9,6)")]
        public decimal Longitude { get; set; }

        [Column("timestamp")]
        public DateTime Timestamp { get; set; }

        [ForeignKey("VehicleId")]
        public Vehicle Vehicle { get; set; }
    }
}
